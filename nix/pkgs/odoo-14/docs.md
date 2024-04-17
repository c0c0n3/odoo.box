Odoo 14
-------
> Nix package docs.

Odoo `14` package. There's no `14` package in Nixpkgs so we've got
to build our own. We look at [version 15][odoo-15] in Nixpkgs to get
an idea of what to package, likely dependencies, etc. but then we
follow a different route to pull everything together.

First off, we re-engineer the Odoo Python package. We put together
a Poetry [project][pypro] to manage Odoo's deps better—Odoo comes
with a `requirements.txt` system, which quite frankly, isn't as good
as Poetry. With a Poetry package in place, we leverage the excellent
`poetry2nix` to get a [corresponding Nix package][pkg].

In the process, we also [fix][patch] Odoo's Gevent server. In fact,
the code to spawn the server blindly assumes the command line to
start Odoo was in the format `python odoo ...`, but this may not be
true in general since a quite common thing to do is to actually use
a shell start script. This is definitely true for our Nix package,
hence the breakage. (See [notes here][pkg] for the gory details.)

Finally we have to build [wkhtmltopdf][wkhtmltopdf] too. Odoo `14`
requires `wkhtmltopdf 0.12.5` but NixOS 23.11 has version `0.12.6`.
This wouldn't be too bad if it wasn't for the fact that version
`0.12.5` depends on `qtwebkit 5.212.0-alpha4` which is abandonware
and so Nix does everything it can to stop you from using it. As a
result, we've got to add it to the "permitted insecure packages"
and compile the whole `qtwebkit` from scratch, which takes a heck
of a long time.




[odoo-15]: https://github.com/NixOS/nixpkgs/blob/nixos-23.11/pkgs/applications/finance/odoo/odoo15.nix
[patch]: ./server.py.patch
[pkg]: ./pkg.nix
[pypro]: ./pyproject.toml
[wkhtmltopdf]: ./wkhtmltopdf.nix
