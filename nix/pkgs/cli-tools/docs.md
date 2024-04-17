CLI Tools
---------
> Nix package docs.

CLI tools to manage a Linux `odoo.box` machine as well as tools to
develop `odoo.box`. There's three shells you can use:

- `linux-admin-shell`: widely-used Linux sys-admin tools. These are
   the CLI tools we install on `odoo.box`. Most of these tools are
   also available on MacOS.
- `dev-shell`: dev tools to develop, test and deploy `odoo.box`.
- `full-shell`: combines all the tools from the two shells above.

Have a look at [admin.nix][admin] to see what tools make up the sys
admin lot. Likewise, [dev.nix][dev] lists all the dev tools.




[admin]: ./admin.nix
[dev]: ./dev.nix
