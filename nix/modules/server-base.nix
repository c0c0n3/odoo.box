#
# TODO. docs.
#
{ config, lib, pkgs, ... }:

with lib;
with types;

{

  options = {
    odbox.devm.enable = mkOption {
      type = bool;
      default = false;
      description = ''
        Enable it to install this dev VM's config.
      '';
    };
  };

  config = let
    enabled = config.odbox.devm.enable;
    psql = config.services.postgresql.package;
  in (mkIf enabled
  {
    # Start from our OS base config.
    odbox.base = {
      enable = true;
      cli-tools = pkgs.odbox.linux-admin-shell.paths;
    };

    # Allow remote access through SSH, even for root.
    services.openssh = {
      enable = true;
      settings.PermitRootLogin = "yes";
    };

    # Get rid of the firewall.
    networking.firewall.enable = false;

    odbox.service-stack = {
      enable = true;
      # bootstrap-mode = true;
      odoo-db-name = "odoo_martel_14";
    };
  });

}
