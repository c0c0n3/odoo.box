#
# Snake oil security for the careless soul.
#
# WARNING: only ever use this package for testing with a local VM!
#
# In the box:
# - Localhost cert. Self-signed, 100-year valid SSL cert for testing
#   on localhost.
# - Passwords. Root and admin sys users as well as Odoo admin user
#   get a generated password of 'abc123'.
#
# We use `vaultgen` to generate all the above and put the content
# of the `generated` dir in this package's root dir. See `vaultgen`
# for the details of the directory structure and what files get
# generated.
#
{
  stdenv, vaultgen
}:
let
  cmd = "${vaultgen}/bin/vaultgen";
  root-pass = "abc123";
  admin-pass = root-pass;
  odoo-admin-pass = root-pass;
in stdenv.mkDerivation {
    pname = "snakeoil-sec";
    version = "1.0.0";

    dontUnpack = true;                                         # (1)

    buildPhase = ''
      BATCH_MODE=1 \
      ROOT_PASSWORD="${root-pass}" \
      ADMIN_PASSWORD="${admin-pass}" \
      ODOO_ADMIN_PASSWORD="${odoo-admin-pass}" \
      ${cmd}
    '';

    installPhase = ''
      mkdir -p $out
      mv generated/* $out/
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
