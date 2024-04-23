#
# See `docs.md` for module documentation.
#
{ config, lib, pkgs, ... }:

with lib;
with types;

{
  options = {
    odbox.service-stack = {
      enable = mkOption {
        type = bool;
        default = false;
        description = ''
          Enable it to install the Odoo service stack.
          The stack is made of a fronting Nginx reverse proxy,
          the Odoo Web service and the Postgres DB backend.
        '';
      };
      odoo-package = mkOption {
        type = package;
        default = pkgs.odbox.odoo-14;
        description = "Odoo package to use.";
      };
      odoo-addons = mkOption {
        type = listOf package;
        default = [ pkgs.odbox.odoo-addons ];
        description = ''
          Nix-packaged Odoo addons to include in the Odoo server.
        '';
      };
      odoo-db-name = mkOption {
        type = str;
        default = "odoo";
        description = "Name of the Odoo Postgres DB.";
      };
      odoo-cpus = mkOption {
        type = ints.positive;
        default = 1;
        description = "Number of CPUs available to run the Odoo server.";
      };
      domain = mkOption {
        type = str;
        default = "localhost";
        description = ''
          Odoo domain name for Nginx's virtual host.
          Since we make the Odoo host the default Nginx server, you won't
          need to set this option unless you'd like to use NixOS's built-in
          support to automatically get and renew TLS certs, in which case,
          you should set this option to the FQDN of the host machine.
        '';
      };
      bootstrap-mode = mkOption {
        type = bool;
        default = false;
        description = ''
          If true, install all the goodies in the the Odoo service
          stack except for actually running the Odoo server. The Odoo
          user and service will be there as well as the `odoo` binary,
          but the server won't run. This is useful if you want to
          bootstrap your Odoo DB and file store yourself—think migrating
          data from another Odoo server. In fact, it's not a good idea to
          have Odoo kick around while you bootstrap its data as experience
          has shown.
          Setting this option to false (the default) makes all the other
          options work normally—i.e. if you enable the stack, everything
          gets installed and runs as you'd expect.
        '';
      };
    };
  };

  config = let
    enabled = config.odbox.service-stack.enable;

    # User and DB names.
    admin-usr = config.odbox.base.admin-username;
    odoo-usr = "odoo";                                         # (2)
    odoo-db = config.odbox.service-stack.odoo-db-name;
    pgadmin-usr = "pgadmin";                                   # (2)
    pgadmin-db = "pgadmin";                                    # (2)

    # Packages.
    postgres-pkg = config.services.postgresql.package;
    odoo-pkg = config.odbox.service-stack.odoo-package;

    # DB.
    db-init = import ./db-init.nix {
      inherit pkgs admin-usr odoo-usr odoo-db pgadmin-usr pgadmin-db;
    };
    pgadmin = import ./pgadmin.nix {};

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

    # Run PgAdmin with a built-in connection to the Odoo DB and only
    # R/W perms on Odoo tables, plus read access to Postgres stats.
    services.pgadmin = pgadmin;

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
# 2. Hardcoded user and DB names. We could make them configurable
# thru module options if ever needed. But for now we don't since
# it's more effort than is worth it.
#