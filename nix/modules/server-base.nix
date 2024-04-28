#
# Base Odoo server machine.
#
# This module brings together several other modules to
# - build our base OS (`odbox.base`);
# - enable SSH;
# - only open the ports we actually need;
# - run the Odoo service stack (`odbox.service-stack`),
#   including PgAdmin.
#
# Each machine we build (dev VM, staging, prod) enables this module
# to bring in the bulk of the required functionality and then bolts
# on machine-specific tweaks like passwords, time zone, swap file,
# and so on.
#
{ config, lib, pkgs, ... }:

with lib;
with types;

{

  options = {
    odbox.server.enable = mkOption {
      type = bool;
      default = false;
      description = ''
        Enable it to install the base Odoo server machine.
      '';
    };
  };

  config = let
    enabled = config.odbox.server.enable;
    psql = config.services.postgresql.package;
  in (mkIf enabled
  {
    # Start from our OS base config.
    odbox.base = {
      enable = true;
      cli-tools = pkgs.odbox.linux-admin-shell.paths;
    };

    # Allow remote access through SSH.
    services.openssh = {
      enable = true;
    };

    # Set up a firewall to let in only SSH and HTTP traffic.
    networking.firewall = {
      enable = true;
      allowedTCPPorts = [ 22 80 443 ];
    };

    # Bring in our Odoo service stack.
    odbox.service-stack = {
      enable = true;
      pgadmin-enable = true;
      # bootstrap-mode = true;
      odoo-db-name = "odoo_martel_14";
    };
  });

}
