Cloud Login
-----------
> Dev VM example scenario.

The dev VM uses standard login, but we can easily change that to
have a more secure set-up with cloud login. As usual, before you
start, you should get a terminal with our Nix shell

```bash
$ cd odoo.box/nix
$ nix shell
```


### Setting up a NixOS config

Now you can generate public and private key pairs in the `devm-aarch64`
directory and then stage the public key file in git

```bash
$ cd nodes/devm-aarch64/
$ vaultgen
  # make script generate everything, skip prod certs step
$ git add vault/ssh/id_ed25519.pub
```

Notice `vaultgen` also generates a `.gitignore` file in the `vault`
dir that excludes everything except from Age-encrypted files and
public keys. We've got to stage the public key file otherwise Nix
won't know how to include it in the machine config we're going to
build.

At this point we can whip together a new dev VM NixOS config that
uses cloud login with the public key we've generated. To do that,
add a `vault.root-ssh-file` and `vault.admin-ssh-file` to link up
the generated public key. Then change `login.mode` from standard
to cloud. Your dev VM vault config should be similar to this

```nix
odbox = {
  login.mode = "cloud";
  vault = {
    snakeoil.enable = true;
    root-ssh-file = ./vault/ssh/id_ed25519.pub;
    admin-ssh-file = ./vault/ssh/id_ed25519.pub;
  };
};
```

Notice you could use Age-encryption instead of snake oil security.
To do that, you should set up either the Agez or Agenix module as
explained in the [Age Secrets][secrets] scenario.


### Deploying the NixOS config

Finally, deploy your new NixOS config

```bash
$ cd ../..
$ nixos-rebuild switch --fast --flake .#devm \
    --target-host root@localhost --build-host root@localhost
```

and try logging in over SSH with the generated identity file from
which the public key was extracted

```bash
$ ssh root@localhost -i vault/ssh/id_ed25519
$ ssh admin@localhost -i vault/ssh/id_ed25519
```

Password login attempts (either at the TTY or through SSH) will fail.


### Cleaning up

Normally after checking the new config is okay, you'd commit your
changes to git (including the public key file) and push upstream.
But here we're just playing around with the dev VM, so don't forget
to clean up when done.

```bash
# undo all repo changes
$ git restore --staged nodes/devm-aarch64
$ git restore nodes/devm-aarch64

# redeploy the original dev VM config
# (login with the identity you generated earlier in the vault dir)
$ NIX_SSHOPTS='-i nodes/devm-aarch64/vault/ssh/id_ed25519' \
  nixos-rebuild switch --fast --flake .#devm \
    --target-host root@localhost --build-host root@localhost

# zap the generated vault dir
$ rm -rf nodes/devm-aarch64/vault
```




[secrets]: ./age-secrets.md
