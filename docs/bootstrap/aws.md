AWS Bootstrap
-------------

TODO

### Restoring data

```bash
$ cd odoo.box/nix
$ nix shell
$ NIX_SSHOPTS='-i nodes/ec2-aarch64/vault/ssh/id_rsa' \
  nixos-rebuild switch --fast --flake .#ec2-boot \
      --target-host root@34.244.18.124 --build-host root@34.244.18.124
```

```bash
$ scp -i nodes/ec2-aarch64/vault/ssh/id_rsa ../_tmp/odoo-dump.sql root@:34.244.18.124/tmp/
$ scp -i nodes/ec2-aarch64/vault/ssh/id_rsa ../_tmp/filestore.tgz root@34.244.18.124:/tmp/
$ ssh -i nodes/ec2-aarch64/vault/ssh/id_rsa root@34.244.18.124
$ cd /tmp
```

```bash
$ sudo -u postgres psql -c 'ALTER USER odoo WITH CREATEDB'
$ sudo -u odoo psql -d postgres -f odoo-dump.sql
$ sudo -u postgres psql -c 'ALTER USER odoo WITH NOCREATEDB'
```

```bash
$ sudo tar -C /var/lib/odoo/data/filestore -xzf filestore.tgz \
    --no-same-owner --no-same-permissions
$ sudo chown odoo:odoo -R /var/lib/odoo/
```

```bash
$ cd odoo.box/nix
$ nix shell
$ NIX_SSHOPTS='-i nodes/ec2-aarch64/vault/ssh/id_rsa' \
  nixos-rebuild switch --fast --flake .#ec2 \
      --target-host root@34.244.18.124 --build-host root@34.244.18.124
```
