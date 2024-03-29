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
  tools = import ./cli-tools { pkgs = sysPkgs; };
  odoo = import ./odoo-14 { pkgs = sysPkgs; };
  addons = import ./odoo-addons { pkgs = sysPkgs; };
  localhost-cert = import ./localhost-cert { pkgs = sysPkgs; };
  vaultgen = import ./vaultgen { pkgs = sysPkgs; };
  snakeoil-sec = import ./snakeoil-sec { pkgs = sysPkgs; inherit vaultgen; };
in rec {
  packages.${system} = {
    default = tools.full-shell;
    dev-shell = tools.dev-shell;
    linux-admin-shell = tools.linux-admin-shell;
    odoo-14 = odoo;
    odoo-addons = addons;
    inherit localhost-cert snakeoil-sec vaultgen;
  };
}
