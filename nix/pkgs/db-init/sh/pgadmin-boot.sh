#!/bin/bash
# ^ The Nix derivation replaces the shebang with a suitable one.

#
# See `docs.md` for script documentation.
#

# Stop at the first error, especially if in a pipeline.
set -ueo pipefail

# Read input args.
superuser_email="$1"
initial_password_file="$2"
db_uri="$3"

# Locate the local connection SQL script.
script_dir=$(dirname "$0")
base_dir=$(readlink -f "${script_dir}/..")
local_conn_script="${base_dir}/sql/pgadmin-local-conn.sql"

# Write the content of the password file to `stdout`, bailing out if
# the password has less than six chars.
# Notice we stop here if the password is too short b/c PgAdmin would
# error out anyway, but the error would be hard to pin down, see:
# - https://github.com/NixOS/nixpkgs/issues/270624
# Code tweaked from:
# - https://github.com/NixOS/nixpkgs/blob/nixos-23.11/nixos/modules/services/admin/pgadmin.nix#L140
read_password() {
    local len=$(wc -m < "${initial_password_file}")
    if [ ${len} -lt 6 ]; then
        echo "Password must be at least 6 characters long."
        exit 1
    fi
    cat "${initial_password_file}"
    # ^ if initial_password_file were empty cat would hang, but it
    # can't be b/c wc would return an error and our `set -e` would
    # make our script stop there.
}

# Run PgAdmin's own script to create and populate the DB tables.
# Notice the script is idempotent, which is great, but it looks like
# there's no way you can specify a CLI arg to tell it how to connect
# to the DB, which isn't great. You've got to have a PgAdmin config
# in `/etc/pgadmin/config_system.py` with the `CONFIG_DATABASE_URI`
# var set to the connection string you'd like to use. In our case,
# since we're using Unix sockets, it should be "postgresql:///" or
# "postgresql:///x" where `x` is the PgAdmin DB name if that's not
# the same name as the PgAdmin role name.
# Sadly, there's no other sane way of doing this.
# Code tweaked from:
# - https://github.com/NixOS/nixpkgs/blob/nixos-23.11/nixos/modules/services/admin/pgadmin.nix#L140
setup_db() {
    local password=$(read_password)
    (
        # Email address:
        echo "${superuser_email}"
        # Password:
        echo "${password}"
        # Retype password:
        echo "${password}"
    ) | pgadmin4-setup
}

# Run our SQL script to set up a Unix socket server connection for
# the PgAdmin UI.
setup_local_connection() {
    psql "${db_uri}" -f "${local_conn_script}"
}


# Let the show begin...
setup_db
setup_local_connection
systemd-notify --ready --status='DB bootstrap completed.'
