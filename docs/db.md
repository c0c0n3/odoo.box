Database
--------
> Our Odoo data stash.

Our Odoo instance uses a Postgres server on the same machine as a DB
backend. Also there's PgAdmin running on the same machine to let Odoo
handymen fix up Odoo data when needed. The PgAdmin DB sits in Postgres
too.


### Connecting

Postgres only accepts Unix socket connections. So you can't connect
any other process to it over TCP, not even on the loopback interface.
So how do we get to the DB?

Odoo connects to Postgres through a Unix socket and so does PgAdmin.
If you want to access the Odoo DB from the Web, you can log into the
PgAdmin UI at `https://odoo-host/pgadmin`. But as a sys admin, you've
got a few more options.

Surely you can SSH into the server machine and then run `psql` as
the Postgres user. For example

```bash
$ ssh -i your.id admin@odoo-host
$ sudo -u postgres psql
```

But you could also use an SSH tunnel. Because there's a Postgres DB
superuser called `admin`, you could first start an SSH tunnel in one
terminal as the remote NixOS `admin` user

```bash
$ ssh -i admin.id admin@odoo-host \
      -L 127.0.0.1:5432:/run/postgresql/.s.PGSQL.5432
#        ↑              ^ Postgres Unix socket on remote host
#        └── use loopback interface, otherwise someone else
#            could try connecting to your machine on port 5432!
```

and then connect whatever DB tool you fancy (e.g. DBeaver) to local
port `5432` to get into Postgres. For example, here's what it'd look
like with `psql` on your local machine

```bash
$ psql postgresql://admin@odoo-host/postgres
```

Notice this is a very secure, password-less kind of connection setup
which you could leverage for Odoo handyman users too. To see how,
say Jane should fix up some Odoo tables. She's a NixOS user (`jane`)
on `odoo-host` and can SSH in there with her SSH identity key. Now,
there's a `pgadmin` Postgres role that can read and write Odoo tables
but has no other privileges besides that. If you create a Postgres
user for Jane with the exact same name as the NixOS user and also
make her a member of `pgadmin`

```sql
CREATE ROLE jane LOGIN IN ROLE pgadmin;
```

then Jane will be able to connect to Postgres through an SSH tunnel
from her machine as explained earlier

```bash
$ ssh -i jane.id jane@odoo-host \
      -L 127.0.0.1:5432:/run/postgresql/.s.PGSQL.5432

# then in another terminal

$ psql postgresql://jane@odoo-host/odoo_martel_14
```

Notice how in this scenario Jane is just a regular NixOS user with
basically no privileges. Ditto for DB access: even though she can
read and write Odoo tables, she can't do anything else to the DB.


### Security

Postgres, PgAdmin and Odoo run as systemd services under their own
respective NixOS daemon users—no login, no privileges, etc. Postgres
only accepts connections on a Unix socket so you can't connect to it
over TCP—not even through the loopback interface. Hence both PgAdmin
and Odoo are forced to use a Unix socket to connect to their respective
DBs.

Postgres relies on peer authentication. So there has to be a DB role
in correspondence of each NixOS user that needs to access the DB. We
ship with the following pre-configured Postgres roles

- Postgres superuser. Traditional Postgres root user.
- Odoo user. Owns the Odoo DB but can't otherwise do anything else
  in the Postgres server, not even create other DBs.
- PgAdmin user. Owns the PgAdmin DB, can read/write Odoo tables and
  read Postgres stats, but besides that, it can't do anything else
  in the Postgres server.

We keep the DB role names the same as the NixOS user names. This way
we avoid having to set up a Postgres identity map. Default names:
`postgres`, `odoo` and `pgadmin` respectively. You can change any
of those names through Nix config though.

Notice Odoo and PgAdmin services have restricted access to the DB
and no access to the NixOS system. Also, the Odoo DB management
module is disabled. This way we limit the amount of damage in case
of an Odoo or PgAdmin Web UI break-in.


### Maintenance

Postgres needs some love every now and then. You should run the usual
maintenance tasks regularly—vacuum, re-index, and [so on][pg-maint].
We could automate these tasks, but we haven't done it yet, so manual
procedure it is for now. But we do have an automated solution for
[backups][backups].




[backups]: ./backups.md
[pg-maint]: https://www.postgresql.org/docs/current/maintenance.html
