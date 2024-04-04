#
# Nixify the script to generate `odbox.vault` secrets.
# Tie the script to the `vaultgen` command.
# See `gen.sh` for the details of what the script does.
#
{
  stdenv, lib, makeWrapper, openssl, openssh, age, mkpasswd
}:
let
  inherit (lib) makeBinPath;
in stdenv.mkDerivation rec {
  pname = "vaultgen";
  version = "1.0.0";

  src = ./.;

  nativeBuildInputs = [ makeWrapper ];
  buildInputs = [ openssl openssh age mkpasswd ];

  installPhase = ''
    install -Dm755 gen.sh $out/bin/vaultgen
    install -Dm444 genlib.sh $out/bin/

    wrapProgram $out/bin/vaultgen --prefix PATH : '${makeBinPath buildInputs}'
  '';
}
