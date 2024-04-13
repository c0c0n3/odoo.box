#
# See `docs.md` for package documentation.
#
{
  stdenv, lib, makeWrapper, openssl, openssh, age, mkpasswd, diceware
}:
let
  inherit (lib) makeBinPath;
in stdenv.mkDerivation rec {
  pname = "vaultgen";
  version = "1.0.0";

  src = ./.;

  nativeBuildInputs = [ makeWrapper ];
  buildInputs = [ openssl openssh age mkpasswd diceware ];

  installPhase = ''
    install -Dm755 gen.sh $out/bin/vaultgen
    install -Dm444 genlib.sh $out/bin/

    wrapProgram $out/bin/vaultgen --prefix PATH : '${makeBinPath buildInputs}'
  '';
}
