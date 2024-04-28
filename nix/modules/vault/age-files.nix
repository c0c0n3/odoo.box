#
# Options to configure the vault with passwords and certificates
# extracted from Age-encrypted files.
# Notice we don't check if the options are set since the implementation
# modules ultimately set the content of these options to the corresponding
# interface options where we've got assertions to check the required fields
# are there.
#
{ config, lib, pkgs, ... }:

with lib;
with types;

{
  options = {
    odbox.vault.age.root-pwd = mkOption {
      type = nullOr path;
      default = null;
      description = ''
        Age-encrypted file containing the root user's password hashed
        in a way `chpasswd` can handle.
      '';
    };
    odbox.vault.age.admin-pwd = mkOption {
      type = nullOr path;
      default = null;
      description = ''
        Age-encrypted file containing the admin user's password hashed
        in a way `chpasswd` can handle.
      '';
    };
    odbox.vault.age.odoo-admin-pwd = mkOption {
      type = nullOr path;
      default = null;
      description = ''
        Age-encrypted file containing the Odoo admin user's clear-text
        password.
      '';
    };
    odbox.vault.age.pgadmin-admin-pwd = mkOption {
      type = nullOr path;
      default = null;
      description = ''
        Age-encrypted file containing the PgAdmin Web UI admin user's
        clear-text password.
      '';
    };
    odbox.vault.age.nginx-cert = mkOption {
      type = nullOr path;
      default = null;
      description = ''
        Age-encrypted file containing the Nginx's TLS certificate.
      '';
    };
    odbox.vault.age.nginx-cert-key = mkOption {
      type = nullOr path;
      default = null;
      description = ''
        Age-encrypted file containing the Nginx's TLS certificate key.
      '';
    };
  };
}
