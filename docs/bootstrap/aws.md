AWS Bootstrap
-------------
> Creating a prod VM on AWS.

We're going to build an EC2 VM to host our Odoo stack to run the
prod show. We'll start from scratch and follow pretty much the same
procedure as that for the [Dev VM][devm]. So we'll keep the commentary
to the bare minimum, read the [Dev VM][devm] page if you need more
details.


### Creating an EC2 instance

We tested our AWS setup with both Graviton (ARM64) and Xeon (x86_64)
instance types. Specifically, we ran Odoo Box on the instance types
below, but any other ARM64 or x86_64 instance type should do.
- ARM64: `m6g.xlarge`, `m6g.2xlarge`, `c6g.xlarge`, `c6g.2xlarge`,
  `t4g.2xlarge`.
- x86_64: `t3.medium`, `t3.2xlarge`.

So start an on-demand EC2 VM, either ARM64 or x86_64, with these
settings:
- AMI: Official NixOS `23.11`.
- One EBS of 200GB to host the whole OS + data.
- One EBS of 10GB to host backups.
- Static IP: e.g. `99.80.119.231`.
- Inbound ports: `22`, `80`, `443`.


### Choosing an Odoo Box config

Pick the Odoo Box config for your EC2 VM's architecture:

- [nodes/ec2-aarch64][ec2-aarch64] for ARM64
- [nodes/ec2-x86_64][ec2-x86_64] for x86_64

Then save your SSH identity key in your local `odoo.box` clone as
either
- `nodes/ec2-aarch64/vault/ssh/id_rsa`; or
- `nodes/ec2-x86_64/vault/ssh/id_rsa`

depending on the Odoo Box config you chose.

The commands in the rest of this guide refer to a scenario with
- EC2 Graviton VM
- VM's IP address of `99.80.119.231`
- SSH identity in `nodes/ec2-aarch64/vault/ssh/id_rsa`

Surely your IP address will be different, replace the above IP with
yours. Likewise, if you have an x86_64 VM, you'll have to use the
`ec2-x86_64` config, so tweak the commands below accordingly. Finally,
if you'd rather keep the SSH identity in a file other than `id_rsa`
in `vault/ssh/`, you can do that but tweak the SSH-related commands
accordingly. Either way, make sure to use the SSH key paired to
`/vault/ssh/id_rsa.pub`.


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
Configs][vault-eg] page.

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
  nixos-rebuild switch --fast --flake .#ec2-aarch64-boot \
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
  nixos-rebuild switch --fast --flake .#ec2-aarch64 \
      --target-host root@99.80.119.231 --build-host root@99.80.119.231
```




[devm]: ./dev-vm.md
[ec2-aarch64]: ../../nix/nodes/ec2-aarch64/
[ec2-x86_64]: ../../nix/nodes/ec2-x86_64/
[odoo-data]: ./odoo-data.md
[vault]: ../../nix/modules/vault/docs.md
[vault-eg]: ../vault-n-login/README.md
