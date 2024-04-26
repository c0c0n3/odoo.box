#
# See `docs.md` for package documentation.
#
{
  stdenv, lib, makeWrapper, postgresql
}:
let
  inherit (lib) makeBinPath;
in stdenv.mkDerivation rec {
  pname = "db-init";
  version = "1.0.0";

  src = ./.;

  nativeBuildInputs = [ makeWrapper ];
  buildInputs = [ postgresql ];

  installPhase = ''
    install -Dm755 sh/pgtest.sh $out/bin/pgtest
    install -Dm755 sh/pgadmin-boot.sh $out/bin/pgadmin-boot
    mv sql $out/

    wrapProgram $out/bin/pgtest --prefix PATH : '${makeBinPath buildInputs}'
  '';
}
