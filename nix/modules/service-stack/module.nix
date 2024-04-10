#
# Service stack to run Odoo.
#
# This module configures the whole service stack to run Odoo on a
# single machine:
# - Odoo multi-processing server (including LiveChat gevent process)
# - Odoo addons
# - Systemd service to run Odoo (including `odoo` sys user)
# - Non-network Postgres DB backend (Odoo connects on Unix sockets)
# - Nginx TLS reverse proxy to expose Odoo to the internet
#
# Notice this module comes with a bootstrap option to migrate an Odoo
# DB and file store from another Odoo server. Also, this module makes
# psql and the Odoo CLI available system-wide to help with maintenance
# tasks.
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
    username = "odoo";
    cfg-file = import ./odoo-config.nix {
      inherit pkgs;
      db-name = config.odbox.service-stack.odoo-db-name;
      cpus = config.odbox.service-stack.odoo-cpus;
    };
    postgres-pkg = config.services.postgresql.package;
    odoo-pkg = config.odbox.service-stack.odoo-package;
    svc = import ./odoo-svc.nix {
      inherit lib username postgres-pkg odoo-pkg cfg-file;
      pwd-file = config.odbox.vault.odoo-admin-pwd-file;
      addons = config.odbox.service-stack.odoo-addons;
      bootstrap = config.odbox.service-stack.bootstrap-mode;
    };
    nginx = import ./nginx.nix {
      sslCertificate = config.odbox.vault.nginx-cert;
      sslCertificateKey = config.odbox.vault.nginx-cert-key;
      domain = config.odbox.service-stack.domain;              # (1)
    };
  in (mkIf enabled
  {
    # Set up the Odoo system user with no privileges.
    users.users."${username}" = {
      isSystemUser = true;
      group = username;
    };
    users.groups."${username}" = {};

    # Start the Odoo server as a systemd service running under the
    # Odoo system user. The Odoo server gets configured with the
    # above config file and loads the given addons. The service's
    # home will be `/var/lib/${username}`.
    systemd.services."${username}" = svc;

    # Run Nginx as a reverse proxy for Odoo.
    services.nginx = nginx;

    # Start Postgres and create a DB user with the same username as
    # the Odoo system user. This way the Odoo service, which runs
    # under the Odoo system user, can connect to Postgres on the
    # Unix socket. Notice we don't create an Odoo DB since most
    # likely you'd want to import your own.
    services.postgresql = {
      enable = true;
      ensureUsers = [{
        name = username;
      }];
    };

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