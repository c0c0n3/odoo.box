#
# See `docs.md` for package documentation.
#
{
  stdenv, vaultgen
}:
let
  cmd = "${vaultgen}/bin/vaultgen";
  root-pass = "abc123";
  admin-pass = root-pass;
  odoo-admin-pass = root-pass;
  pgadmin-admin-pass = root-pass;
in stdenv.mkDerivation {
    pname = "snakeoil-sec";
    version = "1.0.0";

    dontUnpack = true;                                         # (1)

    buildPhase = ''
      ${cmd} root "${root-pass}"
      ${cmd} admin "${admin-pass}"
      ${cmd} odoo-admin "${odoo-admin-pass}"
      ${cmd} pgadmin-admin "${pgadmin-admin-pass}"
      ${cmd} certs
    '';

    installPhase = ''
      mkdir -p $out
      mv vault/* $out/
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
