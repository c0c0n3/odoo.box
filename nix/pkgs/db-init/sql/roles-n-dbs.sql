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
-- PgAdmin connection params for the built-in connection we install.
--

SELECT setting AS sockets
FROM pg_settings
WHERE name = 'unix_socket_directories'
\gset

SELECT setting AS port
FROM pg_settings
WHERE name = 'port'
\gset

SELECT current_database() AS pgdb_name
\gset

\set fn_body 'SELECT ''local'', ' :'sockets' ', ' :port ', ' :'pgdb_name' ', ' :'pgadmin_role' ';'

\connect :pgadmin_db

CREATE OR REPLACE FUNCTION connection_params()
    RETURNS record
    LANGUAGE sql
AS :'fn_body';


--
-- PgAdmin perms for Odoo DB.
--

\connect :odoo_db

GRANT pg_read_all_data TO :pgadmin_role;
GRANT pg_write_all_data TO :pgadmin_role;
