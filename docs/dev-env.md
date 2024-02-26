Dev env
-------
> Picks and shovels.

We use our Nix shell to get proper, isolated and reproducible dev
envs. This is a sort of virtual shell env on steroids which has in
it all the tools you need with the right versions. Plus, it doesn't
pollute your box with libs that could break your existing programs —
everything gets installed in an isolated Nix store dir and made
available only in the Nix shell.

First off, you should install Nix and enable the Flakes extension

```bash
$ sh <(curl -L https://nixos.org/nix/install) --daemon
$ mkdir -p ~/.config/nix
$ echo 'experimental-features = nix-command flakes' >> ~/.config/nix/nix.conf
```

Now you can get into our Nix shell and have some fun with our tools.

```bash
$ nix shell github:c0c0n3/odoo.box?dir=nix
$ aws --version
aws-cli/2.13.33 Python/3.11.6 Darwin/23.2.0 source/arm64 prompt/off
```

Keep in mind if you cloned our repo, then you can also start a Nix
shell directly from there, e.g.

```bash
$ cd odoo.box/nix
$ nix shell
```

Finally besides the dev shell you could also get a shell with the
Linux sys admin tools we use to manage the AWS box. This will work
on MacOS too, except some of the Linux-specific tools won't be there.
Here's how to start a shell which contains both the dev and Linux sys
admin tools:

```bash
$ cd odoo.box/nix
$ nix shell .#dev-shell .#linux-admin-shell
```

Look at `nix/pkgs/cli-tools` to see what gets installed.
