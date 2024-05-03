AWS Bootstrap
-------------
> Creating a prod VM on AWS.


### Creating an EC2 instance

Start an on-demand EC2 Graviton VM
- AMI: Official NixOS `23.11`.
- One EBS of 200GB to host the whole OS + data.
- One EBS of 10GB to host backups.
- Static IP: `99.80.119.231`
- Inbound ports: `22`, `80`, `443`.

We tested this with `m6g.xlarge`, `m6g.2xlarge`, `c6g.xlarge`,
`c6g.2xlarge`, and `t4g.2xlarge` instance types. At the moment
we have a `t4g.2xlarge` instance.

Save your SSH identity key as `nodes/ec2-aarch64/vault/ssh/id_rsa`
in your local `odoo.box` clone. The commands below assume your key
is in that file. If you'd rather keep the key somewhere else, change
the commands below accordingly. Either way, make sure to use the SSH
key paired to `nodes/ec2-aarch64/vault/ssh/id_rsa.pub`.


### Preparing the backup disk

Partition the backup disk using a GPT scheme with just one partition
spanning the entire drive. Call that partition `backup` as this is
the GPT partition label our NixOS config looks for to automatically
mount the backup disk.

```bash
$ cd odoo.box/nix
$ nix shell

$ ssh -i nodes/ec2-aarch64/vault/ssh/id_rsa root@99.80.119.231

$ sudo -i

$ lsblk -f
# ^ should list nvme0n1 and nvme1n1, pick the empty disk!

$ parted -a optimal /dev/nvme1n1 -- mklabel gpt

$ parted -a optimal /dev/nvme1n1 -- mkpart primary ext4 0% 100%
$ parted -a optimal /dev/nvme1n1 -- name 1 backup
```

Now format the partition with ext4.

```bash
$ mkfs.ext4 -L backup /dev/nvme1n1p1
```


### Installing Odoo Box

The EC2 instance uses [Age secrets][vault]. So the first thing we
should do is deploy the Age key to the EC2 VM. Below is the short
version which assumes your key is in your local `odoo.box` clone
under `nodes/ec2-aarch64/vault`. If that's not the case or you'd
like to see some example scenarios first, read the [Vault and Login
Configs][vault] page.

```bash
$ cd odoo.box/nix
$ nix shell
$ scp -i nodes/ec2-aarch64/vault/ssh/id_rsa \
      nodes/ec2-aarch64/vault/age.key root@99.80.119.231:/etc/
```

For the rest, the procedure to install our service stack and Odoo
data is pretty much the same as that detailed in the *Restoring data*
section of [Loading Odoo Data][odoo-data]. Read that for explanations.
The only things that are different here are the NixOS config name,
VM IP, and the fact we deploy using a public key.

First off, deploy the data bootstrap NixOS config.

```bash
$ cd odoo.box/nix
$ nix shell
$ NIX_SSHOPTS='-i nodes/ec2-aarch64/vault/ssh/id_rsa' \
  nixos-rebuild switch --fast --flake .#ec2-boot \
      --target-host root@99.80.119.231 --build-host root@99.80.119.231
```

Then copy over to the VM the DB dump and file store tarball.

```bash
$ scp -i nodes/ec2-aarch64/vault/ssh/id_rsa ../_tmp/odoo-dump.sql root@99.80.119.231:/tmp/
$ scp -i nodes/ec2-aarch64/vault/ssh/id_rsa ../_tmp/filestore.tgz root@99.80.119.231:/tmp/
$ ssh -i nodes/ec2-aarch64/vault/ssh/id_rsa root@99.80.119.231
$ cd /tmp
```

In the VM, restore the DB.

```bash
$ sudo -u odoo psql -d odoo_martel_14 -f odoo-dump.sql
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
      --target-host root@99.80.119.231 --build-host root@99.80.119.231
```




[odoo-data]: ./odoo-data.md
[vault]: ../../nix/modules/vault/docs.md
[vault-eg]: ../vault-n-login/README.md
