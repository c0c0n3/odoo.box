#!/bin/bash
# ^ The Nix derivation replaces the shebang with a suitable one.

#
# See `docs.md` for script documentation.
#

set -ueo pipefail


# This script's enclosing directory.
script_dir=$(dirname "$0")


# Run our Makefile with whatever args you pass.
# Pass in `--debug=v,w` to see what make does.
mk() {
    make -s -f "${script_dir}/Makefile" "$@"
}

#
# Generate the admin password files.
# Do nothing if the files are up-to-date, otherwise remake the ones
# that are out-of-date.
#
# Args:
# - Password. The admin password. If not given, generate a strong,
#   memorable one.
#
admin() {
    admin_password="${1:-}" mk PASSWORDS=admin
    exit 0
}

# Same functionality as admin().
root() {
    root_password="${1:-}" mk PASSWORDS=root
    exit 0
}

# Same functionality as admin().
odoo-admin() {
    odoo_admin_password="${1:-}" mk PASSWORDS=odoo-admin
    exit 0
}

# Same functionality as admin().
pgadmin-admin() {
    pgadmin_admin_password="${1:-}" mk PASSWORDS=pgadmin-admin
    exit 0
}

#
# Generate a pub cert and key for each domain name arg. Also encrypt
# each generated file. If no args are given, generate a default cert
# and key for localhost.
#
# Args:
# - List of domain names.
#
certs() {
    local ds="${@:-localhost}"
    mk DOMAINS="${ds}"
    exit 0
}

#
# Import an external pub cert and key.
# Copy the given files over to the vault and encrypt them.
#
# Args:
# - Cert file. Path to the file containing the pub cert.
# - Key file. Path to the file containing the cert key.
#
import() {
    local cert_path="$1"
    local cert_key_path="$2"

    mk import-cert EXT_CERT="${cert_path}" EXT_CERT_KEY="${cert_key_path}"
    exit 0
}

#
# Generate a graph from the Makefile deps.
# Use an example Makefile with a single password called `pwd` and
# domain name of `dom`. Print the graph definition to `stdout` in
# Graphviz format.
#
graph() {
    mk -Bnd PASSWORDS=pwd DOMAINS=dom | make2graph
    exit 0
}

#
# Make each function defined so far callable from Bash as e.g.
# `bash ./driver.sh certs h1.com h2.edu` or `./driver.sh certs h1.com h2.edu`
# if `driver.sh` has the exec perm set.
#
$*


#
# Run in interactive mode.
# Prompt for each password but generate strong, memorable ones if the
# user doesn't enter it. Also generate a localhost certificate signed
# with the vault CA.
# Do nothing if the files are up-to-date, otherwise remake the ones
# that are out-of-date.
#
mk BATCH_MODE=0 \
   PASSWORDS='root admin odoo-admin pgadmin-admin' \
   DOMAINS=localhost
