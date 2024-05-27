#
# This makefile defines static rules to generate vault files that
# are always required, plus a bunch of generic rules to generate
# passwords and certificates dynamically.
#
# Static rules cater for:
# - SSH identity. ED25519 key pair output in `vault/ssh`.
# - Certificate CA. Key and self-signed pub cert to use as a CA
#   for signing all the certificates we generate. The CA pub cert
#   is a 100-valid, RSA x509 cert in PEM format.
# - Git ignore spec. A `.gitignore` file to make sure sensitive
#   data in the vault dir doesn't accidentally get added to source
#   control.
#
# Generic rules cater for dynamic targets which get specified thru
# input variables.
# - Passwords. For each entry in the `PASSWORDS` list, generate a
#   target for the clear-text password, its SHA-512 and yescrypt
#   hashes as well as corresponding Age-encrypted files.
# - Domain certificates. Likewise, for each entry in the `DOMAINS`
#   list, generate a key and pub cert target file in the certs dir
#   as well as corresponding Age-encrypted file targets.
# - External certificates. If `EXT_CERT` and `EXT_CERT_KEY` hold
#   a path, calling the `import-cert` target will copy the respective
#   files to the certs dir and encrypt them.


# ------------------------------------------------------------------------------
# Input variables
# ------------------------------------------------------------------------------

# Batch mode? If non-zero, never prompt for passwords, otherwise do.
BATCH_MODE ?= 1

# Customisable vault base dir and CA name.
BASE_DIR ?= vault
CA_CN ?= vault-ca

# Variables to define dynamic targets. A space-separated (possibly empty)
# list of vaulues. E.g. `DOMAINS=d1`, `DOMAINS='d1 d2'`.
DOMAINS ?=
PASSWORDS ?=

# Variables to import an external certificate.
EXT_CERT ?=
EXT_CERT_KEY ?=


# ------------------------------------------------------------------------------
# Targets and dirs definition as well as imports
# ------------------------------------------------------------------------------

# Load the Bash lib with the functions we call in each rule.
mkfile_path := $(abspath $(lastword $(MAKEFILE_LIST)))
mkfile_dir := $(dir $(mkfile_path))
lib := ${mkfile_dir}lib.sh

# Vault directories.
passwords_dir := ${BASE_DIR}/passwords
certs_dir := ${BASE_DIR}/certs
ssh_dir := ${BASE_DIR}/ssh

# Static targets we should always build.
age_key := ${BASE_DIR}/age.key
ssh_id := ${ssh_dir}/id_ed25519
ca_key := ${certs_dir}/${CA_CN}-key.pem
ca_cert := ${certs_dir}/${CA_CN}-cert.pem
gitignore := ${BASE_DIR}/.gitignore

# Dynamic targets we generate according to input variables.
# Notice we also pick up certs that were generated or imported in a
# previous run but are not listed in `DOMAINS` for the current run.
# This way we can re-encrypt them if the Age key has changed since
# the time when the certs were generated or imported. (Notice `sort`
# removes dups, so we avoid the "target given more than once in the
# same rule" warning.)
domain_certs := $(foreach d, ${DOMAINS}, \
                             ${certs_dir}/${d}-key.pem \
                             ${certs_dir}/${d}-cert.pem)
existing_certs := $(filter-out %.age, $(wildcard ${certs_dir}/*))
age_tls_files := $(sort $(foreach f, \
                    ${existing_certs} ${domain_certs} ${ca_key} ${ca_cert}, \
                    ${f}.age))
pwd_files := $(foreach p, ${PASSWORDS}, \
                          ${passwords_dir}/${p}.txt \
                          ${passwords_dir}/${p}.sha512 \
                          ${passwords_dir}/${p}.yesc)
age_pwd_files := $(foreach f, ${pwd_files}, ${f}.age)


# ------------------------------------------------------------------------------
# Dependencies and rules
# ------------------------------------------------------------------------------

# Default target to make everything.
.PHONY: all
all: ${gitignore} ${ssh_id} ${age_tls_files} ${age_pwd_files}

.PHONY: import-cert
import-cert: ${age_key}
	mkdir -p "${certs_dir}"
	bash "${lib}" import_cert "${age_key}" ".age" \
							  "${certs_dir}" "${EXT_CERT}" "${EXT_CERT_KEY}"

# Make the .gitignore file.
${gitignore}:
	mkdir -p "${BASE_DIR}"
	bash "${lib}" make_gitignore "${BASE_DIR}" "${age_key}" "${certs_dir}" \
	                             "${passwords_dir}" "${ssh_dir}"

# Make the Age key.
${age_key}:
	mkdir -p "${BASE_DIR}"
	bash "${lib}" make_age_key "${age_key}"

# Make the SSH identity.
${ssh_id}:
	mkdir -p "${ssh_dir}"
	bash "${lib}" make_ssh_id "${ssh_id}"

# Make the CA key and pub cert.
${ca_key} ${ca_cert}:
	mkdir -p "${certs_dir}"
	bash "${lib}" make_cert_file_set "${CA_CN}" "${ca_key}" "${ca_cert}"

# Make each domain target (key and pub cert), after making the CA key
# and certs to sign them.
${certs_dir}/%-key.pem ${certs_dir}/%-cert.pem: ${ca_key} ${ca_cert}
	mkdir -p "${certs_dir}"
	bash "${lib}" make_cert_file_set \
	    "$*" "${certs_dir}/$*-key.pem" "${certs_dir}/$*-cert.pem" \
		"${ca_key}" "${ca_cert}"

# Encrypt each cert and key file, after making the clear-text one
# and the encryption key.
${age_tls_files}: %.age: % ${age_key}
	bash "${lib}" encrypt "${age_key}" "$*" "$@"

# Make each password clear-text file.
$(filter %.txt, ${pwd_files}): %.txt:
	mkdir -p ${passwords_dir}
	bash "${lib}" make_password "$(*F)" "$@" "${BATCH_MODE}"

# Make each SHA-512 password hash, after making the corresponding
# clear-text file.
$(filter %.sha512, ${pwd_files}): %.sha512: %.txt
	bash "${lib}" write_sha512_hash "$<" "$@"

# Make each yescrypt password hash, after making the corresponding
# clear-text file.
$(filter %.yesc, ${pwd_files}): %.yesc: %.txt
	bash "${lib}" write_yescrypt_hash "$<" "$@"

# Encrypt each clear-text password and hash file, after making it
# and after making the encryption key.
${age_pwd_files}: %.age: % ${age_key}
	bash "${lib}" encrypt "${age_key}" "$*" "$@"
