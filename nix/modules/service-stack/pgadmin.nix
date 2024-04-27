#
# Implementation of the PgAdmin functionality declared in the interface.
# We bootstrap the PgAdmin DB and run the PgAdmin Web UI with a built-in
# connection to the Odoo DB and only read/write perms on Odoo tables,
# plus read access to Postgres stats.
#
{ config, lib, pkgs, ... }:

with lib;

{

  config = let
    enabled = config.odbox.service-stack.enable &&
              config.odbox.service-stack.pgadmin-enable;

    # Username, DB name, connection string, email and admin password.
    pgadmin-usr = config.odbox.service-stack.pgadmin-username;
    pgadmin-db = config.odbox.service-stack.pgadmin-db-name;
    pgadmin-db-uri = "postgresql:///${pgadmin-db}";
    admin-email = config.odbox.service-stack.pgadmin-admin-email;
    admin-pwd-file = config.odbox.vault.pgadmin-admin-pwd-file;

    # Packages.
    postgres-pkg = config.services.postgresql.package;
    pgadmin-pkg = config.odbox.service-stack.pgadmin-package;

    # Commands.
    pgadmin-boot = "${pkgs.odbox.db-init}/bin/pgadmin-boot";
    pgadmin-web = "${pgadmin-pkg}/bin/pgadmin4";

    # Service template.
    mkService = { command, path, deps, extraConfig ? {} }:
    {
      inherit path;

      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ] ++ deps;
      requires = [ "network.target" ] ++ deps;

      restartTriggers = [
        "/etc/pgadmin/config_system.py"
        admin-pwd-file
      ];

      serviceConfig = {
        User = pgadmin-usr;
        DynamicUser = true;
        LogsDirectory = pgadmin-usr;
        StateDirectory = pgadmin-usr;
        ExecStart = command;
      } // extraConfig;
    };

  in (mkIf enabled                                             # (3)
  {
    # Create PgAdmin service user with no privileges.
    users.users."${pgadmin-usr}" = {
      isSystemUser = true;
      group = pgadmin-usr;
    };
    users.groups."${pgadmin-usr}"= { };

    # Set up PgAdmin sys config file.
    # Notice this is the only one we can use w/o having to repackage
    # the code to add `config_distro.py` or `config_local.py`.
    environment.etc."pgadmin/config_system.py" = {
      text = ''
        SERVER_MODE = True
        DEFAULT_SERVER_PORT = 5050
        CONFIG_DATABASE_URI = "${pgadmin-db-uri}"
      '';
      mode = "0600";
      user = pgadmin-usr;
      group = pgadmin-usr;
    };

    # Run the PgAdmin DB bootstrap procedure as PgAdmin service user
    # only after Postgres has started.
    # The bootstrap procedure creates and populates tables, plus it
    # sets up a Postgres Unix socket connection the UI can use out
    # of the box.
    systemd.services.pgadmin-setup = mkService {
        deps = [ "postgresql.service" ];
        path = [ pgadmin-pkg postgres-pkg ];
        command = ''
          ${pgadmin-boot} \
              ${escapeShellArg admin-email} \
              ${escapeShellArg admin-pwd-file} \
              ${escapeShellArg pgadmin-db-uri}
        '';
        extraConfig = {
          Type = "notify";                                     # (2)
          NotifyAccess = "all";
        };
    };

    # Run the PgAdmin Web UI as PgAdmin service user only after the
    # bootstrap procedure has completed.
    systemd.services.pgadmin = mkService {
        deps = [ "pgadmin-setup.service" ];
        path = [ postgres-pkg ];
        command = pgadmin-web;
    };
  });

}
# NOTE
# ----
# 1. Why not use NixOS's built-in PgAdmin module? Race conditions.
# The NixOS module bootstraps the PgAdmin DB with a procedure that
# won't work reliably in our case where we use Postgres as a PgAdmin
# config DB instead of the built-in SQLite backend. Now the command
# we and the NixOS module use to bootstrap the PgAdmin DB is the
# `pgadmin4-setup` Python script from the `pgadmin4` Nix package.
# This script won't create a Postgres DB, so we've got to create
# one before the script runs. But to do that, Postgres must be up
# and running, which won't necessarily be the case when the NixOS
# PgAdmin module's systemd `ExecStartPre` fires. Indeed, while the
# systemd docs explicitly state
# > ExecStartPost= is taken into account for the purpose of
# > Before=/After= ordering constraints
# there's no mention of `ExecStartPre` and ordering constraints.
# To prove the point, we tweaked the NixOS PgAdmin module to make
# PgAdmin start after Postgres:
#
#     systemd.services.pgadmin.after = [ "postgresql.service" ];
#     systemd.services.pgadmin.requires = [ "postgresql.service" ];
#
# and created the PgAdmin DB through a script executed in the
# `ExecStartPost` of the Postgres systemd service. Sure as hell,
# every now and then the `pgadmin4-setup` script running as part
# of `ExecStartPre` in the PgAdmin service failed b/c the PgAdmin
# DB wasn't there.
# Long story short: the PgAdmin DB bootstrap should be done as
# a separate systemd service scheduled to run after Postgres but
# before PgAdmin. This seems the only sane way to avoid race
# conditions. So that's what we do.
#
# 2. Service synchronisation. We need systemd to wait until the
# bootstrap script has completed. If it doesn't then you could
# get into a race condition where the bootstrap procedure runs
# concurrently with the PgAdmin UI which will also try creating
# tables and populating the DB---it uses the same setup module
# as `pgadmin4-setup`. To prevent that, we make our setup service
# a systemd "notify" service. This kind of service waits until it
# receives a "ready" notification from the called command. Our
# `pgadmin-boot` command actually uses `systemd-notify` to send
# that signal after the whole bootstrap procedure has completed
# successfully.
#
# 3. DB junk. See:
# - https://github.com/c0c0n3/odoo.box/issues/14
#
# 4. Possibly simpler bootstrap procedure. See:
# - https://github.com/c0c0n3/odoo.box/issues/15
#
