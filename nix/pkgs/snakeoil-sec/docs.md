Snake Oil Security
------------------
> Nix package docs.

Snake oil security for the careless soul.

**WARNING**: only ever use this package for testing with a local VM!

### In the box
- Localhost cert. Self-signed, 100-year valid SSL cert for testing
  on localhost.
- Passwords. All our built-in users (NixOS root & admin, Odoo Web UI
  admin, PgAdmin Web UI admin) get a generated password of 'abc123'.
- SSH keys. ED25519 identity and corresponding public key.

We use `vaultgen` to generate all the above and put the content
of the `vault` dir in this package's root dir. See [vaultgen][vaultgen]
for the details of the directory structure and what files get
generated.


### Decrypting age files

Easy:

```bash
$ cd odoo.box/nix
$ nix shell
$ nix build .#snakeoil-sec
$ age -d -i result/age.key result/passwords/odoo-admin.age
$ age -d -i result/age.key result/certs/localhost-key.pem.age | bat
```

..and so on.




[vaultgen]: ../vaultgen/docs.md
