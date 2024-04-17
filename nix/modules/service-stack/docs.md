Service Stack
-------------
> Nix module docs.

Service stack to run Odoo.


### Overview

This [module][mod] configures a fully-fledged service stack to run
Odoo on a single machine:
- Odoo multi-processing server (including LiveChat gevent process)
- Sane, automatically generated Odoo [config][cfg]
- Odoo [addons][addons]
- [Systemd service][svc] to run Odoo (including `odoo` sys user
  and safe handling of Odoo admin password)
- Non-network Postgres DB backend (Odoo connects on Unix sockets)
- Nginx TLS reverse [proxy][proxy] to expose Odoo to the internet

Also, this module makes `psql` and the Odoo CLI available system-wide
to help with maintenance tasks.

Notice this module comes with a bootstrap option to migrate an Odoo
DB and file store from another Odoo server. In bootstrap mode you
get all the goodies in the the Odoo service stack except for a running
Odoo server. The Odoo user and service will be there as well as the
`odoo` binary, but the server won't run. This is useful if you want
to bootstrap your Odoo DB and file store yourself—think migrating
data from another Odoo server. In fact, it's not a good idea to have
Odoo kick around while you bootstrap its data as experience has shown.


### Example usage

Bootstrap mode:

```nix
odbox.service-stack = {
  enable = true;
  bootstrap-mode = true;
};
```

Normal prod mode:

```nix
odbox.service-stack = {
  enable = true;
  odoo-db-name = "odoo_martel_14";
  odoo-cpus = 4;
};
```




[addons]: ../../pkgs/odoo-addons/docs.md
[cfg]: ./odoo-config.nix
[mod]: ./module.nix
[proxy]: ./nginx.nix
[svc]: ./odoo-svc.nix
