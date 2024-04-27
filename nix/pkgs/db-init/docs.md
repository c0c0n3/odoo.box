DB Init Scripts
---------------
> Nix package docs.

Scripts to initialise the Postgres, Odoo and PgAdmin DBs. We bundle
up a few Pl/pgSQL scripts to prep our DBs as well as some CLI utils,
see below.


### Roles and databases

The [roles and databases script][roles-n-dbs] creates the roles and
DBs we need to run the Odoo service stack.

- Create a Postgres admin role with super-cow powers. This is
  an extra Postgres superuser to represent the DB admin which
  we create in addition to the custom built-in `postgres`
  superuser. This role can login but has no password.
- Create Odoo and PgAdmin roles with login but grant no other
  perms. Both roles can login but have no password.
- Create Odoo and PgAdmin DBs if not there; when creating a DB,
  make the respective role the DB owner.
- Give PgAdmin R/W access to tables, views and sequences in the
  Odoo DB but nothing else. (Notice this includes both the current
  tables/views/sequences and those Odoo may create in the future.)
- Set up a function in the PgAdmin DB to fetch the current Unix
  socket connection params. (See the *PgAdmin local connection*
  section below for the details.)

Notice this script is idempotent. Running it multiple times has the
same effect of running it once.

Call this script with these `psql` input variables
- `admin_role`: the name of the DB admin role.
- `odoo_role`: the name of the Odoo role.
- `odoo_db`: the name of the Odoo database.
- `pgadmin_role`: the name of the PgAdmin role.
- `pgadmin_db`: the name of the PgAdmin database.

Example usage:

```bash
$ sudo -u postgres psql \
       --set=admin_role='admin' \
       --set=odoo_role='odoo' --set=odoo_db='odoo' \
       --set=pgadmin_role='pgadmin' --set=pgadmin_db='pgadmin' \
       -f roles-n-dbs.sql
```

#### Stricter PgAdmin permissions
The script makes the PgAdmin role a member of [pg_read_all_data and
pg_write_all_data][pg-roles]. We could be more strict about perms if
we defined ourselves an Odoo Handyman role. This role would have no
login but members of this role would inherit just the perms we decide
to grant. Below is an example script to do that in such a way that

1. Both Odoo and PgAdmin can connect to the DB;
2. Handyman can read whatever sequences Odoo owns at the moment
   or in the future;
3. Handyman can do CRUD ops on whatever tables Odoo owns at the
   moment or in the future;
4. PgAdmin is a member of Handyman.

Here's the (untested!) Pl/pgSQL script we could use.

```sql
DO
$$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'odoo')
    THEN
        CREATE ROLE odoo LOGIN;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'odoo_handyman')
    THEN
        CREATE ROLE odoo_handyman;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'pgadmin')
    THEN
        CREATE ROLE pgadmin LOGIN;
        GRANT odoo_handyman TO pgadmin;
    END IF;
END
$$
;

\connect odoo

ALTER DEFAULT PRIVILEGES FOR USER odoo
    GRANT SELECT ON SEQUENCES TO odoo_handyman;
ALTER DEFAULT PRIVILEGES FOR USER odoo
    GRANT ALL ON TABLES TO odoo_handyman;
```


### PgAdmin local connection

The [PgAdmin local connection script][local-conn] configures PgAdmin
with a Unix socket connection to the Postgres DB. This script calls
the `connection_params` function that the roles & DBs script creates
to fetch the current Unix socket connection params and then uses them
to create or update a PgAdmin server connection called `local`. This
way, when you log into the PgAdmin UI, you'll have our DB connection
available in the default `Servers` group.

Notice the PgAdmin user has no row level access to the Unix socket
setting in the Postgres DB. If you run the below select statement
as superuser, you'll get back the Unix socket dirs Postgres is using

```sql
SELECT setting
FROM pg_settings
WHERE name = 'unix_socket_directories'
```

But if you run the same statement (either in the Postgres DB or in
the PgAdmin one) as the PgAdmin user, you'll get back nothing, zilch,
nada. Since it's convenient to run the local connection script as
the PgAdmin user (see *PgAdmin bootstrap* section below) and we'd
like to avoid giving PgAdmin too many perms, we need a way for the
PgAdmin user to get hold of the current connection settings. Hence
the `connection_params` function.

Notice this script is idempotent. Running it multiple times has the
same effect of running it once.

Call this script as the PgAdmin user **after** the roles & databases
script has completed **successfully**.

Example usage:

```bash
$ sudo -u pgadmin psql -f pgadmin-local-conn.sql
```


### PgAdmin bootstrap

The [pgadmin-boot][boot] command creates all the required tables in
the PgAdmin DB, populates them and sets up a Unix socket connection
to Postgres for the PgAdmin UI by running the local connection SQL
script.

Since this script is mainly useful when called from a systemd setup
service, we've made a few assumptions. Specifically, the caller must

- have already run the roles & databases script successfully;
- have `/etc/pgadmin/config_system.py` with the `CONFIG_DATABASE_URI`
  var set to connect to Postgres PgAdmin DB over Unix sockets;
- have `psql` and `pgadmin4-setup` (from the `pgadmin4` Nix package)
  in their path;
- run the script as a systemd service under the PgAdmin user.

Notice the URI to set in `CONFIG_DATABASE_URI` should have the
format `postgresql:///<pgadmin-db-name>`. If the PgAdmin username
is the same as the PgAdmin DB name, then `<pgadmin-db-name>` can be
the empty string: `postgresql:///`. Otherwise, you'll have to add
the DB name, e.g. `postgresql:///my-pgadmin-db`. In any case, the
host part of the URI should be empty as Postgres interprets that
as you wanting a [Unix socket connection][pg-uri].

The script takes three unnamed, positional arguments: the name of
the PgAdmin superuser, the path to a file containing the superuser's
login password, and the exact same URI in `CONFIG_DATABASE_URI`.
Notice the PgAdmin superuser is just the UI superuser, that is the
built-in user that can login and create more users, *not* a Postgres
superuser with DB super-cow powers.

Example usage:

```bash
$ sudo -u pgadmin pgadmin-boot admin /run/age/pgadmin-admin postgresql:///
```


### Postgres readiness check

The [pgtest][pgtest] command lets you check if Postgres is running
and ready to accept connections. Any user on the same machine where
Postgres runs can run the script as there's no special permissions
required.

The script takes one unnamed argument which can be either `running`
or `ready`. If you pass in the `running` flag, as in the example
below,

```bash
$ pgtest running
```

the script will print the Postgres main process's PID and return `0`
if Postgres is up and running; otherwise it'll return a non-zero exit
code. If you pass in `ready` instead,

```bash
$ pgtest ready
```

the script will check if Postgres is running and in that case wait
indefinitely until it accepts connections. On connecting to Postgres,
it'll print out the Unix socket and/or TCP socket the server is listening
to—e.g. `/run/postgresql:5432 - accepting connections`. Also it'll
return a `0` exit code. On the other hand, it'll stop and return a
non-zero exit code if Postgres isn't running.

Notice this script assumes the Postgres service runs under the customary
`postgres` user. If that's not the case, use the `PG_SVC_USR` env var
to specify the Postgres service user, e.g.

```bash
$ PG_SVC_USR=postmaster pgtest ready
```




[boot]: ./sh/pgadmin-boot.sh
[local-conn]: ./sql/pgadmin-local-conn.sql
[pg-roles]: https://www.postgresql.org/docs/15/predefined-roles.html
[pg-uri]: https://www.postgresql.org/docs/current/libpq-connect.html#LIBPQ-CONNSTRING
[pgtest]: ./sh/pgtest.sh
[roles-n-dbs]: ./sql/roles-n-dbs.sql
