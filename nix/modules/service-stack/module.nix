#
# Implementation of the core functionality declared in the interface.
# We set up Odoo, Postgres, Nginx & friends here while we leave the
# PgAdmin outside of the core---see `pgadmin.nix` for the PgAdmin
# implementation.
#
{ config, lib, pkgs, ... }:

with lib;
with types;

{

  config = let
    enabled = config.odbox.service-stack.enable;

    # User and DB names.
    admin-usr = config.odbox.login.admin-username;
    odoo-usr = config.odbox.service-stack.odoo-username;
    odoo-db = config.odbox.service-stack.odoo-db-name;
    pgadmin-usr = config.odbox.service-stack.pgadmin-username;
    pgadmin-db = config.odbox.service-stack.pgadmin-db-name;

    # Packages.
    postgres-pkg = config.services.postgresql.package;
    odoo-pkg = config.odbox.service-stack.odoo-package;

    # DB.
    db-init = import ./db-init.nix {
      inherit pkgs admin-usr odoo-usr odoo-db pgadmin-usr pgadmin-db;
    };

    # Odoo.
    cfg-file = import ./odoo-config.nix {
      inherit pkgs odoo-db;
      cpus = config.odbox.service-stack.odoo-cpus;
    };
    svc = import ./odoo-svc.nix {
      inherit lib odoo-usr postgres-pkg odoo-pkg cfg-file;
      pwd-file = config.odbox.vault.odoo-admin-pwd-file;
      addons = config.odbox.service-stack.odoo-addons;
      bootstrap = config.odbox.service-stack.bootstrap-mode;
    };

    # Nginx.
    nginx = import ./nginx.nix {
      sslCertificate = config.odbox.vault.nginx-cert;
      sslCertificateKey = config.odbox.vault.nginx-cert-key;
      domain = config.odbox.service-stack.domain;              # (1)
    };
  in (mkIf enabled
  {
    # Set up the Odoo system user with no privileges.
    users.users."${odoo-usr}" = {
      isSystemUser = true;
      group = odoo-usr;
    };
    users.groups."${odoo-usr}" = {};

    # Start the Odoo server as a systemd service running under the
    # Odoo system user. The Odoo server gets configured with the
    # above config file and loads the given addons. The service's
    # home will be `/var/lib/${odoo-usr}`.
    systemd.services."${odoo-usr}" = svc;

    # Run Nginx as a reverse proxy for Odoo.
    services.nginx = nginx;

    # Run Postgres with the security and DBs we need for Odoo and
    # PgAdmin. Notice our DB init script gets merged with the
    # post-start one of the NixOS Postgres service and executed
    # after it. This is cool as the original post-start script
    # waits for Postgres to be up and running.
    services.postgresql = {
      enable = true;
      authentication = lib.mkForce ''
        local all all              peer
      '';
    };
    systemd.services.postgresql.postStart = db-init;

    # Make psql and odoo CLI available system wide for maintenance
    # tasks.
    environment.systemPackages = [ postgres-pkg  odoo-pkg ];
  });

}
# NOTE
# ----
# 1. TLS certs. At the moment we assume the sys admin takes care of
# getting and renewing TLS certs. But we could automate this step too
# since NixOS comes with ACME built-in support. In this case, the domain
# name should be that of the host machine. Also notice that multi-domain
# configs are also supported.
# See:
# - https://nixos.org/manual/nixos/stable/#module-security-acme-nginx
# - https://nixos.wiki/wiki/Nginx
# - https://discourse.nixos.org/t/nixos-nginx-acme-ssl-certificates-for-multiple-domains
#
