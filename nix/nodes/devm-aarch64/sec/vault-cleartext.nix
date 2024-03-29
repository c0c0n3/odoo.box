#
# Clear-text passwords and certs for testing with the dev VM.
# See snake oil security package.
#
{ config, pkgs, ... }:
{
  odbox.vault = {
    root-pwd-file = "${pkgs.odbox.snakeoil-sec}/passwords/root.sha512";
    admin-pwd-file = "${pkgs.odbox.snakeoil-sec}/passwords/admin.sha512";
    odoo-admin-pwd-file = "${pkgs.odbox.snakeoil-sec}/passwords/odoo-admin";
    nginx-cert = "${pkgs.odbox.snakeoil-sec}/certs/localhost-cert.pem";
    nginx-cert-key = "${pkgs.odbox.snakeoil-sec}/certs/localhost-key.pem";
  };
}
