#
# Snake oil security for the careless soul.
#
# WARNING: only ever use this package for testing with a local VM!
#
# In the box:
# - Localhost cert. Self-signed, 100-year valid SSL cert for testing
#   on localhost. Pub cert: `certs/localhost-cert.pem`; Private key:
#   `certs/localhost-key.pem`.
# - Passwords. Root and admin sys users as well as Odoo admin user
#   get a generated password of 'abc123'. Root and admin get their
#   own password files containing a hash `chpasswd` can handle, whereas
#   Odoo admin gets a file with the clear-text password in it. File
#   with root's hashed password: `passwords/root`; File with admin's
#   hashed password: `passwords/admin`; File with Odoo admin's password:
#   `passwords/odoo-admin`.
# - Age-encrypted files. For each of the above files, except for the
#   cert, a corresponding `.age` file in the same dir that's encrypted
#   using `age` and an `age` key automatically generated. E.g. the content
#   of the Odoo admin password file `passwords/odoo-admin` gets encrypted
#   into `passwords/odoo-admin.age`. The generate `age` key gets output
#   to `age.key` at the root of the package.
#
{
  stdenv, lib, openssl, age
}:
let
  ossl = "${openssl}/bin/openssl";
  keygen = "${age}/bin/age-keygen";
  encrypt = file: ''
    ${age}/bin/age -o "${file}.age" -r $recipient "${file}"
  '';                                                          # (4)
  genEncScript = files: lib.strings.concatLines (map encrypt files);

  root-pass = "abc123";
  admin-pass = root-pass;
  odoo-admin-pass = root-pass;

  certs-dir = "certs";
  passwords-dir = "passwords";
  localhost-cert = "${certs-dir}/localhost-cert.pem";
  localhost-cert-key = "${certs-dir}/localhost-key.pem";
  root-pwd-file = "${passwords-dir}/root";
  admin-pwd-file = "${passwords-dir}/admin";
  odoo-admin-pwd-file = "${passwords-dir}/odoo-admin";
in stdenv.mkDerivation {
    pname = "snakeoil-sec";
    version = "1.0.0";

    dontUnpack = true;                                         # (1)

    buildPhase = ''
      mkdir "${certs-dir}"
      ${ossl} \
        req -x509 -newkey rsa:4096 \
        -days 36500 -nodes -subj '/CN=localhost' \
        -keyout "${localhost-cert-key}" -out "${localhost-cert}"

      mkdir "${passwords-dir}"
      ${ossl} passwd -6 "${root-pass}" > "${root-pwd-file}"
      ${ossl} passwd -6 "${admin-pass}" > "${admin-pwd-file}"
      echo "${odoo-admin-pass}" > "${odoo-admin-pwd-file}"

      ${keygen} -o age.key
      recipient=$(${keygen} -y age.key)
      ${genEncScript [localhost-cert-key root-pwd-file admin-pwd-file
                      odoo-admin-pwd-file]}
    '';

    installPhase = ''
      mkdir -p $out
      mv ./* $out/
    '';                                                       # (2)

}
# NOTE
# ----
# 1. No source. Since we've got no source, the unpack phase would fail
# if we ran it.
# See:
# - https://github.com/NixOS/nixpkgs/issues/23099
#
# 2. Security. Cert key and passwords will wind up in the Nix store
# which is world-readable. Only ever use this package for testing on
# localhost!
#
# 3. CA. We could improve our setup by creating our own Certificate
# Authority and then sign our cert with that CA. This way, you could
# import the CA in e.g. your browser and get rid of the annoying sec
# warning when hitting localhost:443.
# See:
# - https://hackernoon.com/how-to-get-sslhttps-for-localhost-i11s3342
#
# 4. Decrypting age files. Easy:
#
#   $ cd odoo.box/nix
#   $ nix shell
#   $ nix build .#snakeoil-sec
#   $ age -d -i result/age.key result/passwords/odoo-admin.age
#   $ age -d -i result/age.key result/certs/localhost-key.pem.age | bat
#
# ...and so on.
#
