#
# Options to configure the vault with passwords and certificates
# extracted from Age-encrypted files.
#
{ config, lib, pkgs, ... }:

with lib;
with types;

{
  options = {
    odbox.vault.age.root-pwd = mkOption {
      type = path;
      default = abort "missing root password!";
      description = ''
        Age-encrypted file containing the root user's password hashed
        in a way `chpasswd` can handle.
      '';
    };
    odbox.vault.age.admin-pwd = mkOption {
      type = path;
      default = abort "missing admin password!";
      description = ''
        Age-encrypted file containing the admin user's password hashed
        in a way `chpasswd` can handle.
      '';
    };
    odbox.vault.age.odoo-admin-pwd = mkOption {
      type = path;
      default = abort "missing Odoo admin password!";
      description = ''
        Age-encrypted file containing the Odoo admin user's clear-text
        password.
      '';
    };
    odbox.vault.age.nginx-cert = mkOption {
      type = path;
      default = abort "missing Nginx's TLS certificate!";
      description = ''
        Age-encrypted file containing the Nginx's TLS certificate.
      '';
    };
    odbox.vault.age.nginx-cert-key = mkOption {
      type = path;
      default = abort "missing Nginx's TLS certificate key! ";
      description = ''
        Age-encrypted file containing the Nginx's TLS certificate key.
      '';
    };
  };
}
