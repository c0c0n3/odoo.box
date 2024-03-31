#
# Snake oil vault.
# Configure the vault with clear-text passwords and certs for testing
# with the dev VM. The values come from the snake oil security package,
# see there for the details.
#
# WARNING: only ever enable this module for testing locally with the
# dev VM.
#
{ config, lib, pkgs, ... }:

with lib;
with types;

{

  options = {
    odbox.vault.snakeoil.enable = mkOption {
      type = bool;
      default = false;
      description = ''
        Enable it to configure the vault with snake oil security.
      '';
    };
  };

  config = let
    enabled = config.odbox.vault.snakeoil.enable;
  in (mkIf enabled
  {
    odbox.vault = {
      root-pwd-file = "${pkgs.odbox.snakeoil-sec}/passwords/root.sha512";
      admin-pwd-file = "${pkgs.odbox.snakeoil-sec}/passwords/admin.sha512";
      odoo-admin-pwd-file = "${pkgs.odbox.snakeoil-sec}/passwords/odoo-admin";
      nginx-cert = "${pkgs.odbox.snakeoil-sec}/certs/localhost-cert.pem";
      nginx-cert-key = "${pkgs.odbox.snakeoil-sec}/certs/localhost-key.pem";
    };
  });
}
