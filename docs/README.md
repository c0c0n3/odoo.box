Odoo Box Docs
-------------
> The nuts and bolts of running the Odoo show.

We've put together some docs to explain how to build, deploy and
operate our Odoo server as well as an overview of the Nix code we've
developed. Here's what's available:

- [Dev Env][dev]. How we use our Nix shell to get proper, isolated
  and reproducible dev envs. One-liner install with a virtual env
  that doesn't mess up your box.
- [Nix Code Whirlwind Tour][tour]. An overview of the Nix code we
  use to build our servers. You should read this to have an idea
  of the functionality we've packed in our Odoo server.
- [Database][db]. Our Odoo instance uses a Postgres server on the
  same machine as a DB backend. Also there's PgAdmin running on the
  same machine to let Odoo handymen fix up Odoo data when needed.
  Read more about our Odoo data stash in this section.
- [Vault and Login Configs][vault]. Various options you have to
  manage your secrets and login info while still being able to
  securely keep all that stuff in source control. Complete with
  deployment scenarios.
- [Odoo Box From Scratch][boot]. How to bootstrap a fully-fledged
  Odoo server (Nginx, Odoo, module extensions, Postgres, PgAdmin,
  etc.) on NixOS using our Nix flake, including data migration
  from K8s.
- [NixOS Deployment][deploy]. Doing GitOps at the OS-level. Keep
  the code that defines OS deployments in a git repo and then apply
  it to a remote set of machines to update their configuration,
  packages, services, etc. The git repo is the single source of
  truth, the remote machines reflect the deployment state declared
  in the repo.
- [Backups][backup]. Making sure we never lose our Odoo data.
- [Qemu Snippets][qemu]. Providing little tips and snippets to use
  Qemu to simulate cloud nodes.




[backup]: ./backups.md
[boot]: ./bootstrap/README.md
[db]: ./db.md
[deploy]: ./os-deployment.md
[dev]: ./dev-env.md
[qemu]: ./qemu.md
[tour]: ./nix-code-overview.md
[vault]: ./vault-n-login/README.md
