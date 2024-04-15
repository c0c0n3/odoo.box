Nix Code Whirlwind Tour
-----------------------
> Hang tight!

We use Nix to build, deploy and manage our Odoo server. We keep our
Nix code in the (surprise, surprise!) [nix directory][nix-dir]. The
code is organised in three parts, each in its own subdirectory:

- Modules. NixOS modules to assemble system configurations.
- Nodes. System configurations for each machine we run our Odoo
  server on.
- Packages. Software we have packaged to support our modules and
  make our life easier.

Read on for a bit more detail about each part of the Nix code.


### Modules

We've implemented the following NixOS modules:

- [OS Base][os-base]. Convenience module to configure a simple
  system base with CLI tools, Emacs, admin user and password-less
  sudoers.
- [Service Stack][svc-stack]. Fully-fledged service stack to run
  Odoo on a single machine. Includes our Odoo addons, Postgres DB,
  Nginx TLS reverse proxy as well as other tools to help with Odoo
  admin and maintenance tasks.
- [Server Base][svr-base]. Strings together the two modules above,
  enables SSH and sets up a firewall to let in only SSH and HTTP
  traffic.
- [Login][login]. Choose how the root and admin users can log in.
  In cloud mode, these users can only log in over SSH with their
  respective SSH identities. In standard mode, they can log in both
  through TTY and SSH using passwords. Plus, they can also log in
  over SSH using their respective identities.
- [Vault][vault]. All our password and TLS settings consolidated in
  one place for easy management and auditing. We encrypt vault files
  and then automatically decrypt them on the target machine directly
  into RAM (`tmpfs`) to avoid storing them on disk. This way even
  secrets can be safely kept in Git and in the Nix store, all of
  which enables a full-on GitOps approach where we keep everything
  to get a running system, except for the Odoo DB and file store,
  in source control.
- [Swap File][swap]. Enables swapping on a swap file.


### Nodes

A full-blown NixOS system for each machine we run our Odoo server
on. Each machine we build basically just enables the Server Base
module to bring in the bulk of the required functionality and then
bolts on machine-specific tweaks like passwords, time zone, swap
file, and so on. Also, each machine config comes in two variants:
one to bootstrap Odoo data and the other to run the actual Odoo
service stack with that data.

At the moment we have the following configs:

- [Dev VM][devm]. Qemu ARM64 VM to run and test the whole shebang
  in the comfort of your laptop.
- [EC2][ec2]. EC2 Graviton VM to run the prod show. It works on
  `m6g.xlarge`, `m6g.2xlarge`, `c6g.xlarge`, `c6g.2xlarge`, and
  `t4g.2xlarge` instance types.


### Packages

We've developed the following Nix packages:

- [CLI Tools][cli]. CLI tools to manage a Linux server as well as
  tools to develop our Odoo Nix stack. Complete with Nix shells you
  can use on your laptop too.
- [Odoo 14][odoo]. There's no `14` package in Nixpkgs so we've got
  to build our own. In the process, we re-engineer the Odoo Python
  package and also fix Odoo's Gevent server. Finally, we package a
  `wkhtmltopdf` version Odoo can actually use.
- [Odoo Addons][addons]. Martel's Odoo addons collection. This too
  is a full-on GitOps enabler:we keep everything to get a running
  system, except for the Odoo DB and file store, in source control.
- [Vaultgen][vaultgen]. This package provides the `vaultgen` command
  you typically use to populate the files (secrets) the vault module
  requires.
- [Snake Oil Security][snakeoil-sec]. Packages test secrets you can
  use with the dev VM out of the box, without having to put together
  a vault.




[addons]: ../nix/pkgs/odoo-addons/docs.md
[cli]: ../nix/pkgs/cli-tools/docs.md
[devm]: ../nix/nodes/devm-aarch64/
[ec2]: ../nix/nodes/ec2-aarch64/
[login]: ../nix/modules/login/docs.md
[nix-dir]: ../nix/
[odoo]: ../nix/pkgs/odoo-14/docs.md
[os-base]: ../nix/modules/os-base.nix
[snakeoil-sec]: ../nix/pkgs/snakeoil-sec/docs.md
[svc-stack]: ../nix/modules/service-stack/docs.md
[svr-base]: ../nix/modules/server-base.nix
[swap]: ../nix/modules/swap-file.nix
[vault]: ../nix/modules/vault/docs.md
[vaultgen]: ../nix/pkgs/vaultgen/docs.md