Odoo Box
--------
> All of Martel's Odoo stack on just one NixOS machine.

So we've migrated our Odoo service away from K8s to a dedicated NixOS
server. In the process, we've developed quite a bit of functionality
that wasn't easy to implement in our old K8s setup and which resulted
in slashing IT Ops and hardware costs while improving reliability and
performance at the same time.

Below is an overview of the main features, read up about the details
in the [docs][docs].


## Features

### Odoo Service Stack

A fully-fledged, multi-architecture (x86-64 and ARM64) service stack
to run Odoo on a single machine:
- Odoo multi-processing server, including LiveChat gevent process.
- Sane, automatically generated Odoo config.
- Nix-packaged Odoo addons.
- systemd service to run Odoo, including daemon user and secure
  handling of Odoo admin password.
- systemd service to run PgAdmin, including daemon user, zero-config
  DB init with automatic connection to Postgres from the Web UI,
  and secure handling of PgAdmin Web UI admin password.
- Non-network Postgres DB backend (both Odoo and PgAdmin connect
  to Unix sockets) with automatic creation of Odoo & PgAdmin DBs
  and roles as well as strict security policies.
- Nginx TLS reverse proxy to safely expose Odoo and PgAdmin to the
  internet.
- CLI tools to help with maintenance tasks.
- Minimal NixOS base system with firewall and SSH.

From DBs to services to security, we wire everything together to
make the whole service stack work out of the box without any extra
manual config. As for security, we stick to Least Privilege and Zero
Trust principles.


### Operations

Nix and GitOps, a marriage made in heaven. We use Nix to build,deploy
and manage our Odoo server and do GitOps all the way down to the operating
system level. We keep the code that defines a running server in this
git repo and then apply it to a remote set of machines to update their
configuration, packages, services, etc. This also includes secrets and
other security settings as well as Odoo addons, but obviously excludes
the Odoo DB and file store. Basically the git repo is the single source
of truth, the remote machines reflect the deployment state declared in
the repo.

Also, we've developed a few things to make the sys admin's life a
bit easier:
- Login. Choose how the root and admin users can log in. In cloud
  mode, these users can only log in over SSH with their respective
  SSH identities. In standard mode, they can log in both through
  TTY and SSH using passwords. Plus, they can also log in over SSH
  using their respective identities.
- Vault. All our password and TLS settings consolidated in one place
  for easy management and auditing. We encrypt vault files and then
  automatically decrypt them on the target machine directly into RAM
  (`tmpfs`) to avoid storing them on disk. This way even secrets can
  be safely kept in Git and in the Nix store, all of which enables a
  full-on GitOps approach.
- Odoo data migration. Support to migrate an Odoo DB and file store
  from another Odoo server. Complete with K8s migration scripts.
- Built-in EC2 Graviton support. One-liner install for `m6g.xlarge`,
  `m6g.2xlarge`, `c6g.xlarge`, `c6g.2xlarge`, and `t4g.2xlarge`
  instance types.


### Development & Testing

- Dev Env. Nix shell to get proper, isolated and reproducible dev
  envs. This is a sort of virtual shell env on steroids which has
  in it all the tools you need with the right versions. Plus, it
  doesn't pollute your box with libs that could break your existing
  programs—everything gets installed in an isolated Nix store dir
  and made available only in the Nix shell. Multi-architecture
  (x86-64 and ARM64) and available both on Linux and MacOS.
- Dev VM. Qemu VM to run and test the whole prod server in the
  comfort of your laptop. Why spin up a cloud VM or buy a separate
  dev box when you can easily test a prod clone on your laptop?




[docs]: ./docs/README.md
