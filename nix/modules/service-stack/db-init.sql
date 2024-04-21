--
-- Intialise the Odoo and PgAdmin DBs.
--
-- * Create Odoo and PgAdmin roles with login but grant no other
--   perms.
-- * Create Odoo and PgAdmin DBs if not there; when creating a DB,
--   make the respective role the DB owner.
-- * Give PgAdmin R/W access to tables, views and sequences in the
--   Odoo DB but nothing else. (Notice this includes both the current
--   tables/views/sequences and those Odoo may create in the future.)
--
-- Notice this script is idempotent. Running it multiple times has
-- the same effect of running it once.
--
-- Input variables
-- * odoo_role: the name of the Odoo role.
-- * odoo_db: the name of the Odoo database.
-- * pgadmin_role: the name of the PgAdmin role.
-- * pgadmin_db: the name of the PgAdmin database.
--
-- Example usage:
-- $ sudo -u postgres psql \
--        --set=odoo_role='odoo' --set=odoo_db='odoo' \
--        --set=pgadmin_role='pgadmin' --set=pgadmin_db='pgadmin' \
--        -f file-containing-this-script.sql
--


--
-- Odoo and PgAdmin roles.
--

SELECT
    'CREATE ROLE ' || :'odoo_role' || ' LOGIN'
WHERE NOT EXISTS (
    SELECT FROM pg_roles WHERE rolname = :'odoo_role'
)\gexec

SELECT
    'CREATE ROLE ' || :'pgadmin_role' || ' LOGIN'
WHERE NOT EXISTS (
    SELECT FROM pg_roles WHERE rolname = :'pgadmin_role'
)\gexec


--
-- Odoo and PgAdmin DBs.
--

SELECT
    'CREATE DATABASE ' || :'odoo_db' ||
    ' TEMPLATE = template0 OWNER = ' || :'odoo_role'
WHERE NOT EXISTS (
    SELECT FROM pg_database WHERE datname = :'odoo_db'
)\gexec

SELECT
    'CREATE DATABASE ' || :'pgadmin_db' || ' OWNER = ' || :'pgadmin_role'
WHERE NOT EXISTS (
    SELECT FROM pg_database WHERE datname = :'pgadmin_db'
)\gexec


--
-- PgAdmin perms for Odoo DB.
-- See:
-- * https://www.postgresql.org/docs/15/predefined-roles.html
--

\connect :odoo_db

GRANT pg_read_all_data TO :pgadmin_role;
GRANT pg_write_all_data TO :pgadmin_role;

/*
NOTE
----
We could be more strict about perms if we defined ourselves an Odoo
Handyman role. This role would have no login but members of this role
would inherit just the perms we decide to grant. Below is an example
script to do that in such a way

1. Both Odoo and PgAdmin can connect to the DB;
2. Handyman can read whatever sequences Odoo owns at the moment
   or in the future;
3. Handyman can do CRUD ops on whatever tables Odoo owns at the
   moment or in the future;
4. PgAdmin is a member of Handyman.

Here's the (untested!) psql script we could use.

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

*/