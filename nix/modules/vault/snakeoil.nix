#
# See `docs.md` for module documentation.
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
      root-pwd-file = "${pkgs.odbox.snakeoil-sec}/passwords/root.yesc";
      admin-pwd-file = "${pkgs.odbox.snakeoil-sec}/passwords/admin.yesc";
      odoo-admin-pwd-file = "${pkgs.odbox.snakeoil-sec}/passwords/odoo-admin.txt";
      pgadmin-admin-pwd-file = "${pkgs.odbox.snakeoil-sec}/passwords/pgadmin-admin.txt";
      nginx-cert = "${pkgs.odbox.snakeoil-sec}/certs/localhost-cert.pem";
      nginx-cert-key = "${pkgs.odbox.snakeoil-sec}/certs/localhost-key.pem";
    };
  });
}
