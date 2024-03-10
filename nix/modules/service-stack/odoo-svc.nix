#
# Generate the systemd entry for the Odoo service.
# Tweaked from:
# - https://github.com/NixOS/nixpkgs/blob/nixos-23.11/nixos/modules/services/finance/odoo.nix
#
{ lib, username, postgres-pkg, odoo-pkg, addons, cfg-file }:
with lib;
let
  odoo-bin = "${odoo-pkg}/bin/odoo";
  addon-paths = concatMapStringsSep "," escapeShellArg addons;
  addons-opt = optionalString (addons != []) "--addons-path=${addon-paths}";
in {
  wantedBy = [ "multi-user.target" ];
  after = [ "network.target" "postgresql.service" ];

  # pg_dump
  path = [ postgres-pkg ];

  requires = [ "postgresql.service" ];
  script = "HOME=$STATE_DIRECTORY ${odoo-bin} ${addons-opt} -c ${cfg-file}";

  serviceConfig = {
    DynamicUser = true;
    User = username;
    StateDirectory = username;
  };
}