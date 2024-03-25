#
# TODO docs.
#
{ config, lib, pkgs, ... }:

with lib;
with types;

{
  options = {
    odbox.vault.root-pwd-file = mkOption {
      type = path;
      default = "${pkgs.odbox.snakeoil-sec}/passwords/root";
      description = ''
        File containing the root user's password hashed in a way `chpasswd`
        can handle.
      '';
    };
    odbox.vault.admin-pwd-file = mkOption {
      type = path;
      default = "${pkgs.odbox.snakeoil-sec}/passwords/admin";
      description = ''
        File containing the admin user's password hashed in a way `chpasswd`
        can handle.
      '';
    };
    odbox.vault.odoo-admin-pwd-file = mkOption {
      type = path;
      default = "${pkgs.odbox.snakeoil-sec}/passwords/odoo-admin";
      description = ''
        File containing the Odoo admin user's clear-text password.
      '';
    };
  };
}
