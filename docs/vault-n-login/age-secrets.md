Age Secrets
-----------
> Dev VM example scenario.

The dev VM uses snake oil security, but we can easily change that
to have a secure set-up with Age-encrypted secrets. As usual, before
you start, you should get a terminal with our Nix shell

```bash
$ cd odoo.box/nix
$ nix shell
```


### Setting up a NixOS config

Now you can generate Age-encrypted secrets in the `devm-aarch64`
directory, copy the generated Age identity over to the dev VM and
stage the Age-encrypted files in git

```bash
$ cd nodes/devm-aarch64/
$ vaultgen
  # make script generate everything, skip prod certs step
$ scp vault/age.key root@localhost:/etc/
$ git add vault
```

Notice `vaultgen` also generates a `.gitignore` file in the `vault`
dir that excludes everything except from Age-encrypted files and
public keys. We've got to stage the secrets otherwise Nix won't know
how to include them in the machine config we're going to build.

At this point we can whip together a new dev VM NixOS config that
uses the secrets we've generated. To do that, zap the `vault.snakeoil`
option, add a `vault.age` stanza to link up the Age-encrypted files
and enable Agez. Your dev VM vault config should be similar to this

```nix
odbox.vault = {
  age = {
    root-pwd = ./vault/passwords/root.yesc.age;
    admin-pwd = ./vault/passwords/admin.yesc.age;
    odoo-admin-pwd = ./vault/passwords/odoo-admin.age;
    pgadmin-admin-pwd = ./vault/passwords/pgadmin-admin.age;
    nginx-cert = ./vault/certs/localhost-cert.pem.age;
    nginx-cert-key = ./vault/certs/localhost-key.pem.age;
  };
  agez.enable = true;
};
```

If you'd rather use Agenix instead of Agez, then just replace the
`agez.enable = true;` line in  the above Nix expression with
`agenix.enable = true;`. Either way, the result is going to be the
same: the secrets get packed in a Nix derivation, the derivation
gets shipped to the dev VM and on system activation the chosen
module will decrypt the secrets and make them available as files
in a `tmpfs` mount.


### Deploying the NixOS config

Finally, deploy your new NixOS config

```bash
$ cd ../..
$ nixos-rebuild switch --fast --flake .#devm \
    --target-host root@localhost --build-host root@localhost
```

and try logging in over SSH with the passwords in the clear-text
files in the `vault/passwords` dir. Then do the same at the TTY.
Also verify the Odoo and PgAdmin Web UI admin passwords as well
as the Nginx certs.


### Cleaning up

Normally after checking the new config is okay, you'd commit your
changes to git (including the Age-encrypted files) and push upstream.
But here we're just playing around with the dev VM, so don't forget
to clean up when done.

```bash
# undo all repo changes
$ git restore --staged nodes/devm-aarch64
$ git restore nodes/devm-aarch64

# redeploy the original dev VM config
# (login with the root password you generated earlier in the vault dir)
$ nixos-rebuild switch --fast --flake .#devm \
    --target-host root@localhost --build-host root@localhost

# zap the generated vault dir
$ rm -rf nodes/devm-aarch64/vault
```
