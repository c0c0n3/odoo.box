Odoo Box Docs
-------------
> ...still a work in progress!

We've put together some docs to explain how to build, deploy and
operate our Odoo server as well as an overview of the Nix code we've
developed. Here's what's available:

- [Dev Env][dev]. How we use our Nix shell to get proper, isolated
  and reproducible dev envs. One-liner install with a virtual env
  that doesn't mess up your box.
- [Nix Code Whirlwind Tour][tour]. An overview of the Nix code we
  use to build our servers. You should read this to have an idea
  of the functionality we've packed in our Odoo server.
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
- [Qemu Snippets][qemu]. Providing little tips and snippets to use
  Qemu to simulate cloud nodes.




[boot]: ./bootstrap/README.md
[deploy]: ./os-deployment.md
[dev]: ./dev-env.md
[qemu]: ./qemu.md
[tour]: ./nix-code-overview.md
[vault]: ./vault-n-login/README.md
