#
# This module groups together all our password and TLS settings.
# Other modules read the values this module config holds to set up
# passwords, TLS, etc. for services and users.
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
    odbox.vault.nginx-cert = mkOption {
      type = path;
      default = "${pkgs.odbox.snakeoil-sec}/certs/localhost-cert.pem";
      description = "Path to the Nginx's TLS certificate.";
    };
    odbox.vault.nginx-cert-key = mkOption {
      type = path;
      default = "${pkgs.odbox.snakeoil-sec}/certs/localhost-key.pem";
      description = "Path to the Nginx's TLS certificate key.";
    };
  };
}
