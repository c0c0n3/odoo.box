Service Stack
-------------
> Nix module docs.

Service stack to run Odoo.


### Overview

This [module][iface] configures a fully-fledged service stack to run
Odoo on a single machine:
- Odoo multi-processing server, including LiveChat gevent process.
- Sane, automatically generated Odoo [config][cfg].
- Odoo [addons][addons].
- [Systemd service][svc] to run Odoo, including daemon user and
  secure handling of Odoo admin password.
- [Systemd service][pgadmin] to run PgAdmin, including daemon user,
  zero-config DB init with automatic connection to Postgres from
  the Web UI, and secure handling of PgAdmin Web UI admin password.
- Non-network Postgres DB [backend][mod] (both Odoo and PgAdmin
  connect to Unix sockets) with [automatic creation][init] of Odoo
  & PgAdmin DBs and roles as well as strict security policies.
- Nginx TLS reverse [proxy][proxy] to safely expose Odoo and PgAdmin
  to the internet.

Also, this module makes `psql` and the Odoo CLI available system-wide
to help with maintenance tasks.

From DBs to services to security, we wire everything together to
make the whole service stack work out of the box without any extra
manual config. As for security, we stick to Least Privilege and Zero
Trust principles.

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

  # optionally
  pgadmin-enable = true;
};
```

Normal prod mode:

```nix
odbox.service-stack = {
  enable = true;
  odoo-db-name = "odoo_martel_14";
  odoo-cpus = 4;

  # optionally
  pgadmin-enable = true;
};
```




[addons]: ../../pkgs/odoo-addons/docs.md
[cfg]: ./odoo-config.nix
[iface]: ./interface.nix
[init]: ./db-init.nix
[mod]: ./module.nix
[pgadmin]: ./pgadmin.nix
[proxy]: ./nginx.nix
[svc]: ./odoo-svc.nix
