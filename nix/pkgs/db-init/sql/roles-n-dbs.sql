--
-- See `docs.md` for script documentation.
--

--
-- Admin, Odoo and PgAdmin roles.
--

SELECT
    'CREATE ROLE ' || :'admin_role' ||
    ' LOGIN SUPERUSER CREATEDB CREATEROLE BYPASSRLS REPLICATION'
WHERE NOT EXISTS (
    SELECT FROM pg_roles WHERE rolname = :'admin_role'
)\gexec

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
--

\connect :odoo_db

GRANT pg_read_all_data TO :pgadmin_role;
GRANT pg_write_all_data TO :pgadmin_role;
