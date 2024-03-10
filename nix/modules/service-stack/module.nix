#
# TODO docs
#
{ config, lib, pkgs, ... }:

with lib;
with types;

{
  options = {
    services.odbox-stack = {
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
        description = "Odoo domain name for Nginx config.";
      };
    };
  };

  config = let
    enabled = config.services.odbox-stack.enable;
    username = "odoo";
    cfg-file = import ./odoo-config.nix {
      inherit pkgs;
      admin-pwd = "";  # TODO should come from encrypted file---see age.
      db-name = config.services.odbox-stack.odoo-db-name;
      cpus = config.services.odbox-stack.odoo-cpus;
    };
    postgres-pkg = config.services.postgresql.package;
    odoo-pkg = config.services.odbox-stack.odoo-package;
    svc = import ./odoo-svc.nix {
      inherit lib username postgres-pkg odoo-pkg cfg-file;
      addons = config.services.odbox-stack.odoo-addons;
    };
    nginx = import ./nginx.nix {
      domain = config.services.odbox-stack.domain;
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