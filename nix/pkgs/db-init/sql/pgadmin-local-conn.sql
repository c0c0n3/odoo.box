--
-- See `docs.md` for script documentation.
--

--
-- Create or update our built-in connection to the local Postgres
-- server over a Unix socket.
-- Notice `roles-n-dbs.sql` takes care of creating and refreshing
-- the `connection_params` function with the current Unix socket
-- connection settings.
-- Also notice when we create the connection we set an empty password
-- and ask PgAdmin to save it. This way the PgAdmin UI won't show that
-- annoying (and useless in our case as we use peer auth) password
-- prompt when you hit the local server connection.
--
MERGE INTO public.server s
USING (
    SELECT name, sockets, port, pgdb_name, role
    FROM connection_params()
    AS (name text, sockets text, port integer, pgdb_name text, role text)
) conn
ON s.name = conn.name
WHEN MATCHED THEN
    UPDATE SET
        host = conn.sockets,
        port = conn.port,
        maintenance_db = conn.pgdb_name,
        username = conn.role
WHEN NOT MATCHED THEN
    INSERT (user_id, servergroup_id, name, host, port, maintenance_db,
            username, password, save_password, tunnel_port, connection_params)
    VALUES (1, 1, conn.name, conn.sockets, conn.port, conn.pgdb_name,
            conn.role, '', 1, '22', '{}')
;
