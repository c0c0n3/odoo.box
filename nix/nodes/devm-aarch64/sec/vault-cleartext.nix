{ config, pkgs, ... }:
{
  odbox.vault = {
    root-pwd-file = "${pkgs.odbox.snakeoil-sec}/passwords/root";
    admin-pwd-file = "${pkgs.odbox.snakeoil-sec}/passwords/admin";
    odoo-admin-pwd-file = "${pkgs.odbox.snakeoil-sec}/passwords/odoo-admin";
    nginx-cert = "${pkgs.odbox.snakeoil-sec}/certs/localhost-cert.pem";
    nginx-cert-key = "${pkgs.odbox.snakeoil-sec}/certs/localhost-key.pem";
  };
}
