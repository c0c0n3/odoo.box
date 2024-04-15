Vault and Login Configs
-----------------------
> Example scenarios.

We're going to reconfigure the dev VM with different login and vault
settings to have concrete examples of usage scenarios. You can easily
try the same configurations we're going to look at here with other
machines after applying some obvious, small tweaks to the examples
below.

Before you dive in, you should review the docs about the vault and
login modules as well as the `vaultgen` and snake oil security packages.
The [Nix Code Whirlwind Tour][code-overview] is a good starting point
to get to know these modules and packages, but then you should read
up about each one in their respective doc pages.

All the examples below assume your dev VM is already up and running.

- [Age Secrets][secrets]. How to have a secure GitOps set-up with
  Age-encrypted secrets.
- [SSH Keys][ssh-keys]. How to configure SSH keys for login.
- [Cloud Login][cloud-login]. How to enable a more secure set-up
  with cloud login.

Notice there's an [issue with the Odoo admin password][issue]. If
you update it, then you'll have to bounce the Odoo service to make
it pick up the new value.




[cloud-login]: ./cloud-login.md
[code-overview]: ../nix-code-overview.md
[issue]: https://github.com/c0c0n3/odoo.box/issues/10
[secrets]: ./age-secrets.md
[ssh-keys]: ./ssh-keys.md
