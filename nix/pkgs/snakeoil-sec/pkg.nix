#
# Snake oil security for the careless soul.
#
# WARNING: only ever use this package for testing with a local VM!
#
# In the box:
# - Localhost cert. Self-signed, 100-year valid SSL cert for testing
#   on localhost. Pub cert: `certs/localhost-cert.pem`; Private key:
#   `certs/localhost-key.pem`.
# - Hashed passwords. Root and admin sys users as well as Odoo admin
#   user get a generated password of 'abc123'. Each user gets its
#   own password file containing a hash `chpasswd` can handle. File
#   with root's hashed password: `passwords/root`; File with admin's
#   hashed password: `passwords/admin`; File with Odoo admin's hashed
#   password: `passwords/odoo-admin`.
#
{
  stdenv, openssl
}:
let
  cmd = "${openssl}/bin/openssl";

  root-pass = "abc123";
  admin-pass = root-pass;
  odoo-admin-pass = root-pass;

  certs-dir = "certs";
  passwords-dir = "passwords";
in stdenv.mkDerivation {
    pname = "snakeoil-sec";
    version = "1.0.0";

    dontUnpack = true;                                         # (1)

    buildPhase = ''
      mkdir "${certs-dir}"
      ${cmd} \
        req -x509 -newkey rsa:4096 \
        -days 36500 -nodes -subj '/CN=localhost' \
        -keyout "${certs-dir}/localhost-key.pem" \
        -out "${certs-dir}/localhost-cert.pem"

      mkdir "${passwords-dir}"
      ${cmd} passwd -6 "${root-pass}" > "${passwords-dir}/root"
      ${cmd} passwd -6 "${admin-pass}" > "${passwords-dir}/admin"
      ${cmd} passwd -6 "${odoo-admin-pass}" > "${passwords-dir}/odoo-admin"
    '';

    installPhase = ''
      mkdir -p $out
      mv "${certs-dir}" $out/
      mv "${passwords-dir}" $out/
    '';                                                       # (2)

}
# NOTE
# ----
# 1. No source. Since we've got no source, the unpack phase would fail
# if we ran it.
# See:
# - https://github.com/NixOS/nixpkgs/issues/23099
#
# 2. Security. The cert key and hashed passwords will wind up in the
# Nix store which is world-readable. Only ever use this package for
# testing on localhost!
#
# 3. CA. We could improve our setup by creating our own Certificate
# Authority and then sign our cert with that CA. This way, you could
# import the CA in e.g. your browser and get rid of the annoying sec
# warning when hitting localhost:443.
# See:
# - https://hackernoon.com/how-to-get-sslhttps-for-localhost-i11s3342
#