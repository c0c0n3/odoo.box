Loading Odoo Data
-----------------
> Feeding the newborn

After instantiating a fully functional Odoo stack with Nix, you've
still got to transfer the prod data from the K8s cluster to the new
NixOS machine. This boils down to two things: restore the Odoo DB
and file store.


### Extracting data

To be able to make Odoo run on the new NixOS machine in the same way
it was in the K8s cluster, you need to load the NixOS machine with
all the Odoo data in the K8s cluster. Specifically, you should have
a Postgres dump of the Odoo DB and a tarball of the Odoo file store.
How do you get them? You should follow the procedure below.

#### Odoo shutdown
First off, shut down the Odoo service so we can make a consistent
DB dump and file store tarball. To do that simply set to zero the
number of replicas in the Odoo deployment.

```bash
$ kubectl -n martel scale --replicas=0 deployment odoo-community
```

Wait until all the Odoo pods are gone before moving on to the next
steps below.

#### DB dump
Second, dump the Odoo DB to a file. Connect to the master Postgres
node, use `pg_dump` to extract the data and then copy it over to
your local host like in the example below.

```bash
$ kubectl -n martel exec -it acid-martel-0 -- sh
$ pg_dump -U postgres -f odoo-dump.sql -O -n public odoo_martel_14
$ exit
$ kubectl -n martel cp acid-martel-0:/home/postgres/odoo-dump.sql odoo-dump.sql
```

Notice the `pg_dump` flags above. You should use the same flags to
make sure the SQL commands output in the file
- don't assign ownership—so the owner will be the role used when
  restoring;
- and only export stuff in the `public` schema—this is all we need
  since the other two schemas got set up and populated by Patroni/Spilo
  and we won't need them in the new DB.

Also notice we don't use the `-C` flag. This flag outputs a command
to create the DB itself from `template0`, DB comments, any DB config
settings and a command to connect to the newly created DB. We don't
need any of this. In fact, we've got our own script to create the DB
from `template0` and there's no DB config we need to export.


#### File store tarball
The Odoo pod keeps its file store under `/bitnami/odoo` which is a
PVC mount. Since we shut down Odoo, we can't use any of the Odoo pods
to make a tarball of the file store. Instead we'll start a minimal
pod with Bash and `tar` on it, mount the Odoo PVC on that pod and
finally extract the data we need. Put the content of the file below
in a file called `pod.yaml`—e.g. `cat > pod.yaml`, copy-paste, ctrl+d.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: odoo-data
  namespace: martel
spec:
  containers:
  - name: odoo-data
    image: docker.io/bash
    command: ["bash"]
    args: ["-c", "while true; do sleep 3600; done"]
    volumeMounts:
    - mountPath: /bitnami/odoo
      name: odoo-data
      readOnly: true
  volumes:
  - name: odoo-data
    persistentVolumeClaim:
      claimName: odoo
```

After deploying this pod to the cluster, get into it to make a tarball
of the Odoo file store, copy the tarball over to your machine and then
zap the pod.

```bash
$ kubectl -n martel apply -f pod.yaml
$ kubectl -n martel exec -it odoo-data -- bash
$ tar -czf filestore.tgz -C bitnami/odoo/data/filestore odoo_martel_14
$ exit
$ kubectl -n martel cp odoo-data:/filestore.tgz filestore.tgz
$ kubectl -n martel delete -f pod.yaml
```


### Restoring data

Now we're ready to feed Odoo :-) First off, you should transition
the NixOS target machine into Odoo bootstrap mode. To do that, just
deploy the `<hostname>-boot` NixOS config where `hostname` is that
of your target machine. Here's an example with the dev VM as a target

```bash
$ cd odoo.box/nix
$ nix shell
$ nixos-rebuild switch --fast --flake .#devm-boot \
    --target-host root@localhost --build-host root@localhost
```

This way we get the whole Odoo stack up and running except for the
actual Odoo server. This is to stop Odoo messing around with DB and
file store init while we're busy restoring them to what they looked
like in the K8s cluster.

After rebuilding NixOS with this config, copy over the data you extracted
earlier to the NixOS target machine, SSH into it and then go to the
location where you copied the files. For example

```bash
# replace localhost with the actual machine IP or domain name
$ scp odoo-dump.sql admin@localhost:/tmp/
$ scp filestore.tgz admin@localhost:/tmp/
$ ssh admin@locahost
$ cd /tmp
```

To restore the DB, run

```bash
$ sudo -u odoo psql -d odoo_martel_14 -f odoo-dump.sql
```

Notice our DB init scripts create the Odoo DB upfront and the `odoo`
user has no create-DB permission. In fact, we want to run Odoo with
the smallest possible set of privileges. This also means you won't
be able to use Odoo's Web UI to create and restore DBs.

To restore the file store, run

```bash
$ sudo tar -C /var/lib/odoo/data/filestore -xzf filestore.tgz \
    --no-same-owner --no-same-permissions
$ sudo chown odoo:odoo -R /var/lib/odoo/
```

At this point the last thing left to do is to reconfigure NixOS
to run the full Odoo stack. To do that, just deploy the `<hostname>`
NixOS config where `hostname` is that of your target machine. Here's
an example with the dev VM as a target

```bash
$ cd odoo.box/nix
$ nix shell
$ nixos-rebuild switch --fast --flake .#devm \
    --target-host root@localhost --build-host root@localhost
```

After taking this config live, you should be able to access the
Odoo Web UI on the target NixOS box from your local machine.
