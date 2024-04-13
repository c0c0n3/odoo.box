Martel's Odoo Addons
--------------------
> Nix package docs.

Martel's Odoo addons collection. This package provides the source of
each addon Martel uses in prod. Sources are conveniently laid out in
the package output dir so you can simply add the output dir to your
Odoo server's addons path to make them available to the server.

Notice we weren't tracking the addon sources in the old K8s prod
deployment, but now we're trying to fix that. First off, the addons
Martel develops get fetched straight from their respective repos.
For all the others, we use the [vendor/addons/][src] dir in this
repo. This dir started off as a [copy][pr] of the files in the old
K8s deployment. Now, every time we'd like to update a plugin, we
should
1. fetch the new source;
2. update the corresponding plugin dir in [vendor/addons/][src]
   with the new files;
3. tag our repo and release a new version `v` along the lines
   of [this one][tag];
4. update our [Odoo addons Nix package][pkg] to fetch the
   [vendor/addons/][src] dir from that new version `v`.

In an ideal world, we wouldn't do (1), (2) and (3). We'd fetch a
specific version straight from the plugin's repo. See [this issue][iss]
about it.




[iss]: https://github.com/c0c0n3/odoo.box/issues/2
[pkg]: ./pkg.nix
[pr]: https://github.com/c0c0n3/odoo.box/pull/1
[src]: ../../../vendor/addons/
[tag]: https://github.com/c0c0n3/odoo.box/releases/tag/vendor-addons-08-mar-2024
