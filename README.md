Odoo Box
--------
> All of Martel's Odoo stack on just one NixOS machine.

So we've migrated our Odoo service away from K8s to a dedicated NixOS
server. In the process, we've developed quite a bit of functionality
that wasn't easy to implement in our old K8s setup and which resulted
in slashing IT Ops and hardware costs while improving reliability and
performance at the same time.

Below is an UML-ish deployment diagram followed by an overview of
the main features, read up about the details in the [docs][docs].

![Deployment diagram][dia.deployment]


## Features

### Odoo Service Stack

A fully-fledged, multi-architecture (x86-64 and ARM64) service stack
to run Odoo on a single machine:
- Odoo multi-processing server, including LiveChat gevent process
  and configurable user session timeout.
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
- TLS certificates. Automatic request, installation and renewal of
  TLS certs. We use Let's Encrypt as a CA in prod, but we've also
  rolled out our own Smallstep CA to test locally and in non-prod
  envs.
- Odoo data migration. Support to migrate an Odoo DB and file store
  from another Odoo server. Complete with K8s migration scripts.
- Backups. Automatic hot and cold backups with flexible schedules.
  Notice that thanks to our Nix-powered GitOps approach, backing
  up and restoring a machine is a breeze. We just need to back up
  the Odoo DB and file store since our repo contains everything
  else you need to instantiate our Odoo Box. With a snapshot of
  the Odoo DB and file store at a point in time, you can restore
  your machine to the exact same state it was at that point in
  time with just a couple of commands.
- Built-in EC2 support. One-line install for Graviton (ARM64) and
  Intel (x86_64) instance types.


### Development & Testing

We believe in local-first and reproducible development. Each dev
should be able to install all the tools they need with a single
command and the tool chain should be exactly the same for everyone
in the team. Also, every dev should be able to test and tinker with
Odoo Box locally without affecting other devs, prod or having to
rely on cloud providers, not even for tricky scenarios like getting
or renewing TLS certificates.

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




[dia.deployment]: ./docs/diagrams/deployment.colour.png
[docs]: ./docs/README.md
