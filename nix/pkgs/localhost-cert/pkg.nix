#
# Generate a self-signed, 100-year valid SSL cert for testing on
# localhost.
# Put the cert and key in the out dir with file names, `cert.pem`
# and `key.pem`, respectively.
#
{
  stdenv, libressl
}:
let
  openssl = "${libressl}/bin/openssl";
in stdenv.mkDerivation {
    pname = "localhost-cert";
    version = "1.0.0";

    dontUnpack = true;                                         # (1)

    buildPhase = ''
      ${openssl} \
        req -x509 -newkey rsa:4096 \
        -days 36500 -nodes -subj '/CN=localhost' \
        -keyout key.pem -out cert.pem
    '';

    installPhase = ''
      mkdir -p $out
      mv cert.pem $out/
      mv key.pem $out/
    '';                                                       # (2)

}
# NOTE
# ----
# 1. No source. Since we've got no source, the unpack phase would fail
# if we ran it.
# See:
# - https://github.com/NixOS/nixpkgs/issues/23099
#
# 2. Security. The cert key will wind up in the Nix store which is
# world-readable. Only ever use this package for testing on localhost!
#