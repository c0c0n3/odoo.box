AWS Bootstrap
-------------
> Creating a prod VM on AWS.


### Creating an EC2 instance

Start an on-demand EC2 Graviton VM
- AMI: Official NixOS `23.11`.
- One EBS of 200GB to host the whole OS + data.
- Inbound ports: `22`, `80`, `443`.

We tested this with `m6g.xlarge`, `m6g.2xlarge`, `c6g.xlarge`,
`c6g.2xlarge`, and `t4g.2xlarge` instance types. At the moment
we have a `t4g.2xlarge` instance with
- public FQDN: `ec2-34-254-91-221.eu-west-1.compute.amazonaws.com`
- hostname: `ip-172-31-3-61.eu-west-1.compute.internal`
- IP: `34.254.91.221`


### Restoring data

Same procedure as that detailed in the *Restoring data* section of
[Loading Odoo Data][odoo-data]. Read that for explanations. The only
things that are different here are the NixOS config name, VM IP, and
the fact we deploy using a public key.

First off, deploy the data bootstrap NixOS config.

```bash
$ cd odoo.box/nix
$ nix shell
$ NIX_SSHOPTS='-i nodes/ec2-aarch64/vault/ssh/id_rsa' \
  nixos-rebuild switch --fast --flake .#ec2-boot \
      --target-host root@34.254.91.221 --build-host root@34.254.91.221
```

Then copy over to the VM the DB dump and file store tarball.

```bash
$ scp -i nodes/ec2-aarch64/vault/ssh/id_rsa ../_tmp/odoo-dump.sql root@34.254.91.221:/tmp/
$ scp -i nodes/ec2-aarch64/vault/ssh/id_rsa ../_tmp/filestore.tgz root@34.254.91.221:/tmp/
$ ssh -i nodes/ec2-aarch64/vault/ssh/id_rsa root@34.254.91.221
$ cd /tmp
```

In the VM, restore the DB.

```bash
$ sudo -u postgres psql -c 'ALTER USER odoo WITH CREATEDB'
$ sudo -u odoo psql -d postgres -f odoo-dump.sql
$ sudo -u postgres psql -c 'ALTER USER odoo WITH NOCREATEDB'
```

Still in the VM, recreate the file store.

```bash
$ sudo tar -C /var/lib/odoo/data/filestore -xzf filestore.tgz \
    --no-same-owner --no-same-permissions
$ sudo chown odoo:odoo -R /var/lib/odoo/
```

Back to your laptop, deploy the NixOS config with the full Odoo
stack.

```bash
$ cd odoo.box/nix
$ nix shell
$ NIX_SSHOPTS='-i nodes/ec2-aarch64/vault/ssh/id_rsa' \
  nixos-rebuild switch --fast --flake .#ec2 \
      --target-host root@34.254.91.221 --build-host root@34.254.91.221
```




[odoo-data]: ./odoo-data.md
