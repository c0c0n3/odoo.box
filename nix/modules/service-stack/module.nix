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
    # Feature flags.
    enabled = config.odbox.service-stack.enable;
    autocerts = config.odbox.service-stack.autocerts;

    # User and DB names.
    admin-usr = config.odbox.login.admin-username;
    admin-email = config.odbox.login.admin-email;
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
    sesh-timeout = config.odbox.service-stack.odoo-session-timeout;
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
    reaper = import ./odoo-sesh-reaper.nix {
      inherit odoo-usr;
      older-than = sesh-timeout;
    };

    # Nginx.
    nginx = import ./nginx.nix {
      inherit autocerts;
      sslCertificate = config.odbox.vault.nginx-cert;
      sslCertificateKey = config.odbox.vault.nginx-cert-key;
      domain = config.odbox.service-stack.domain;
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

    # Schedule a service to zap inactive Odoo sessions.
    # The service runs under the Odoo system user and its home will
    # be `/var/lib/${odoo-usr}`.
    systemd.services.odoo-session-reaper = reaper;

    # Run Nginx as a reverse proxy for Odoo.
    # Also accept ACME terms and set the admin email as a reg email,
    # just in case autocerts is turned on. If it's turned off these
    # values won't be used anyway, so we don't care.
    services.nginx = nginx;
    security.acme.acceptTerms = true;
    security.acme.defaults.email = admin-email;

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
