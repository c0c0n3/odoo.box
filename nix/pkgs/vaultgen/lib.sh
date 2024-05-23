#
# Lib functions to generate, import and encrypt secrets. At the
# moment we use Age for encryption and we only deal with passwords
# and TLS certificates. See functions below.
#

#
# Stop as soon as something errors out, especially in a pipeline.
# We do this because the function below typically get called from
# a Bash interpreter instead of being imported into another script,
# so if there's multiple statements in a function without the flags
# below the function would run all of them.
#
set -ueo pipefail


#
# Generate an ED25519 key pair (identity) with no comment and passphrase.
#
# Args:
# - ID file. Path to the file where to write the key pair.
#
make_ssh_id() {
    local ssh_id="$1"
    ssh-keygen -t ed25519 -C '' -q -N '' -f "${ssh_id}"
}
# NOTE
# ----
# 1. Pub key. The above command generates a `.pub` key file with the
# pub key in it. You can always extract the pub key from the private
# with `ssh-keygen -y -f your_pvt_key`.
# 2. OpenSSL. You could use OpenSSL to generate keys too. E.g.
#   $ openssl genpkey -algorithm ed25519 -out id.pem
#   $ openssl pkey -in id.pem -pubout -out id-pub.pem
# But the pub key won't be in the same OpenSSH format, which is why
# we use `ssh-keygen` instead.

#
# Generate a simple certificate and optionally sign it with a CA.
# Generate the cert as a 100-valid, RSA x509 cert in PEM format. If
# given a CA key and cert, then use them to sign the generated cert;
# otherwise self-sign it.
#
# Args:
# - CN. The CN name for the certificate to generate.
# - Key file. Path to the file where to write the cert key.
# - Cert file. Path to the file where to write the pub cert.
# - CA key. Optional CA key file to sign the certificate. If given,
#   the CA certificate must be given too.
# - CA cert. Optional CA cert file to sign the generated certificate.
#
make_cert_file_set() {
    local cn="$1"
    local key="$2"
    local cert="$3"

    if (( $# > 3 )); then
        local ca_key="$4"
        local ca_cert="$5"

        openssl req -x509 -newkey rsa:4096 -days 36500 -nodes \
            -subj "/CN=${cn}" \
            -keyout "${key}" -out "${cert}" \
            -CAkey "${ca_key}" -CA "${ca_cert}" 2> /dev/null
    else
        openssl req -x509 -newkey rsa:4096 -days 36500 -nodes \
            -subj "/CN=${cn}" \
            -keyout "${key}" -out "${cert}" 2> /dev/null
    fi
}
# NOTE
# ----
# 1. Suppressing errors. Not a good thing to do, but `openssl` always
# prints rubbish chars on stderr when generating a key which clutters
# our screen in interactive mode.
# 2. GnuTLS. Should we use `certtool` instead? It looks like that's
# what some NixOS peeps use to generate certs:
# - https://github.com/NixOS/nixpkgs/blob/c6fd903606866634312e40cceb2caee8c0c9243f/nixos/tests/custom-ca.nix#L80

#
# Write a clear-text password to file.
#
# Args:
# - File name. The name of the file where to write the clear-text
#   password.
# - Clear-text password. The password to use. If none given, generate
#   a strong, memorable one.
#
write_password_file() {
    local out_file="$1"
    local clear_text="${2:-}"

    if [ -z "${clear_text}" ]; then
        clear_text=$(diceware)
    fi
    printf "${clear_text}" > "${out_file}"
}

#
# Make the password file, possibly prompting for a clear-text password
# to write in it.
# In batch mode (default), read the password value from the env var
# `<name>_password`, where `name` is the input password file name,
# e.g. `admin_password`, then write that value as is to file. If the
# var isn't defined or set to empty, then  generate a strong, memorable
# password and write it to the specified file.
# In interactive mode, prompt the user for a password and if they
# don't enter one generate a strong, memorable one, then, in either
# case, write the password to the specified file.
#
# Args:
# - Name. The file name (without extension) of the password to write.
# - File. Path to the password file to write.
# - Batch mode. "1" (default) for batch mode, "0" for interactive
#   mode.
#
make_password() {
    local name="$1"
    local out_file="$2"
    local batch_mode="${3:-1}"

    local password_env_var="$(printf ${name} | tr '-' '_')_password"
    local password=""
    local msg="${name}'s password [leave empty to generate one]: "

    if [ "${batch_mode}" = "0" ]
    then
        read -s -p "${msg}" password
        printf "\n"
    else
        password="${!password_env_var}"
    fi
    write_password_file "${out_file}" "${password}"
}

#
# Compute the SHA-512 hash of a clear-text password and write it
# to a given file.
#
# Args:
# - Clear text. Path to the file containing the clear-text password.
# - Output file. Path to the file where to write the hashed password.
#
write_sha512_hash() {
    local clear_text="$1"
    local out_file="$2"
    cat "${clear_text}" | mkpasswd -m sha-512 -s > "${out_file}"
}

#
# Compute the yescrypt hash of a clear-text password and write it
# to a given file.
#
# Args:
# - Clear text. Path to the file containing the clear-text password.
# - Output file. Path to the file where to write the hashed password.
#
write_yescrypt_hash() {
    local clear_text="$1"
    local out_file="$2"
    cat "${clear_text}" | mkpasswd -m yescrypt -s > "${out_file}"
}

#
# Generate an Age key (identity) to encrypt/decrypt data.
#
# Args:
# - Key file. Path to the file where to write the key.
#
make_age_key() {
    local out_file="$1"
    age-keygen -o "${out_file}" 2> /dev/null
}
# NOTE
# ----
# 1. Suppressing errors. Not a good thing to do, but `age-keygen`
# always prints the pub key to stderr which clutters our screen
# in interactive mode.

#
# Encrypt a file with the `age` command.
#
# Args:
# - Age key. Path to the Age encryption key.
# - Input file. Path to the file to encrypt.
# - Output file. Path to the file where to write the encrypted
#   content.
#
encrypt() {
    local age_key="$1"
    local in_file="$2"
    local out_file="$3"

    local recipient=$(age-keygen -y "${age_key}")
    age -o "${out_file}" -r $recipient "${in_file}"
}

import_cert() {
    local age_key="$1"
    local age_file_ext="$2"
    local certs_dir="$3"
    local cert="$4"
    local cert_key="$5"

    local cert_file_name=$(basename "${cert}")
    local cert_key_file_name=$(basename "${cert_key}")

    cp -n "${cert}" "${certs_dir}"
    cp -n "${cert_key}" "${certs_dir}"
    encrypt "${age_key}" "${certs_dir}/${cert_file_name}" \
                         "${certs_dir}/${cert_file_name}${age_file_ext}"
    encrypt "${age_key}" "${certs_dir}/${cert_key_file_name}" \
                         "${certs_dir}/${cert_key_file_name}${age_file_ext}"
}

make_gitignore() {
    local base_dir="$1"
    local age_key_file="$2"
    local certs_dir="$3"
    local passwords_dir="$4"
    local ssh_dir="$5"

    local age_identity=$(basename "${age_key_file}")
    local certs=$(basename "${certs_dir}")
    local passwords=$(basename "${passwords_dir}")
    local ssh=$(basename "${ssh_dir}")

    cat <<EOF > "${base_dir}/.gitignore"
# Ignore the Age identity
/${age_identity}

# Ignore everything in ${certs} except for Age-encrypted files.
/${certs}/*
!/${certs}/*.age

# Ignore everything in ${passwords} except for Age-encrypted files.
/${passwords}/*
!/${passwords}/*.age

# Ignore everything in ${ssh} except for public key files.
/${ssh}/*
!/${ssh}/*.pub

EOF
}


#
# Make each function in this script callable from Bash as e.g.
# `bash ./lib.sh func arg1 arg2` or `./lib.sh func arg1 arg2`
# if `lib.sh` has the exec perm set.
#
$*
