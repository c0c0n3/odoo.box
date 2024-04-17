Dev Env
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

When you run the `nix shell` command without any arguments, you get
into the default shell. This shell contains all the tools for local
development plus the Linux sys admin tools we use to manage the AWS
box. (The sys admin tools are available on MacOS too, except for a
few of them which are Linux-specific.) Look at `nix/pkgs/cli-tools`
to see what gets installed.

If you don't need the whole tool shebang, you could just instantiate
a shell with the dev tools like this

```bash
$ cd odoo.box/nix
$ nix shell .#dev-shell
```

This way you won't need to download and build lots of stuff in your
Nix store. Likewise, you could just instantiate the sys admin tools

```bash
$ cd odoo.box/nix
$ nix shell .#linux-admin-shell
```

Finally notice that if you combine the above two

```bash
$ cd odoo.box/nix
$ nix shell .#dev-shell .#linux-admin-shell
```

you get the same tools as in the default shell.
