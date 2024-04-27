#!/bin/bash
# ^ The Nix derivation replaces the shebang with a suitable one.

#
# See `docs.md` for script documentation.
#

set -ueo pipefail

source $(dirname "$0")/genlib.sh


# Input vars for batch mode.
: "${BATCH_MODE:=}"
: "${ROOT_PASSWORD:=}"
: "${ADMIN_PASSWORD:=}"
: "${ODOO_ADMIN_PASSWORD:=}"
: "${PGADMIN_ADMIN_PASSWORD:=}"
: "${DOMAIN:=localhost}"
: "${PROD_CERT:=}"
: "${PROD_CERT_KEY:=}"

# Password file names and corresponding password values for batch mode.
pwd_files=("root" "admin" "odoo-admin" "pgadmin-admin")
batch_pwds=("${ROOT_PASSWORD}" "${ADMIN_PASSWORD}" "${ODOO_ADMIN_PASSWORD}" \
            "${PGADMIN_ADMIN_PASSWORD}")

# Run the script in batch mode.
run_batch_mode() {
    make_dirs
    make_gitignore
    make_age_key
    make_ssh_id

    for k in "${!pwd_files[@]}"; do
        make_password_files "${pwd_files[k]}" "${batch_pwds[k]}"
    done
    make_cert_files "${DOMAIN}"
    if [ "${PROD_CERT}" != "" ] && [ "${PROD_CERT_KEY}" != "" ]; then
        import_cert_files "${PROD_CERT}" "${PROD_CERT_KEY}"
    fi
}

# Run the script in interactive mode.
run_interactive_mode() {
    make_dirs
    make_gitignore
    make_age_key
    make_ssh_id

    for f in "${pwd_files[@]}"; do
        read -s -p "${f}'s password [leave empty to generate one]: " password
        printf "\n"
        make_password_files "${f}" "${password}"
    done

    read -p "self-signed certificate's domain [localhost]: " domain
    make_cert_files "${domain:-localhost}"

    read -p "prod pub certificate [press enter to skip]: " cert
    if [ "${cert}" != "" ]; then
        read -p "prod certificate key: " key
        if [ -z "${key}" ]; then
            printf "no prod certificate key entered, skipping prod certs\n"
            exit 0
        fi
        import_cert_files "${cert}" "${key}"
    fi
}


if [ -z "${BATCH_MODE}" ]
then
    run_interactive_mode
else
    run_batch_mode
fi
