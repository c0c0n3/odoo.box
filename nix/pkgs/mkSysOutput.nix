#
# Function to generate the Flake output for a given system.
#
{ # System label---e.g. "x86_64-linux", "x86_64-darwin", etc.
  system,
  # The Nix package set for the input system, possibly with
  # overlays from other Flakes bolted on.
  sysPkgs,
  ...
}:
let
  tools = import ./cli-tools/pkg.nix { pkgs = sysPkgs; };
in rec {
  packages.${system} = {
    default = tools.dev-shell;
    dev-shell = tools.dev-shell;
    linux-admin-shell = tools.linux-admin-shell;
  };
}
