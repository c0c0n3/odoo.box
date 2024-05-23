#
# See `docs.md` for package documentation.
#
{
  stdenv, lib, bash, coreutils, gnumake, makeWrapper, makefile2graph,
  openssl, openssh, age, mkpasswd, diceware
}:
let
  inherit (lib) makeBinPath;
in stdenv.mkDerivation rec {
  pname = "vaultgen";
  version = "1.0.0";

  src = ./.;

  nativeBuildInputs = [ makeWrapper ];
  buildInputs = [
    bash coreutils gnumake makefile2graph
    openssl openssh age mkpasswd diceware
  ];

  installPhase = ''
    install -Dm755 driver.sh $out/bin/vaultgen
    install -Dm444 lib.sh $out/bin/
    install -Dm444 Makefile $out/bin/

    wrapProgram $out/bin/vaultgen --prefix PATH : '${makeBinPath buildInputs}'
  '';
}
