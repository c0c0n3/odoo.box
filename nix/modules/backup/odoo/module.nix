#
# Implementation of the Odoo backup functionality declared in the
# interface.
# We set up systemd timers and services to run hot and cold backups.
# We use `pg_dump` to extract DB defs and data, whereas `rsync` takes
# care of syncing the file store to the backup area.
#
{ config, lib, pkgs, ... }:

with lib;
with types;

{

  config = let
    # Feature flag.
    enabled = config.odbox.backup.odoo.enable;

    # User, DB names and schedules.
    odoo-usr = config.odbox.service-stack.odoo-username;
    odoo-db = config.odbox.service-stack.odoo-db-name;
    hot-schedule = config.odbox.backup.odoo.hot-schedule;

    # Packages.
    sudo = pkgs.sudo;
    postgres = config.services.postgresql.package;
    rsync = pkgs.rsync;

    # Backup base dir.
    basedir = config.odbox.backup.basedir;

  in (mkIf enabled
  {
    systemd.services.odoo-hot-backup = {
      description = "Odoo DB and filestore hot backup to ${basedir}";

      requires = [ "postgresql.service" ];

      path = [ sudo postgres rsync ];

      script = import ./backup-script.nix {
        inherit odoo-usr odoo-db basedir;
      };

      serviceConfig = {
        Type = "oneshot";
        User = "root";
      };

      startAt = hot-schedule;
    };

  });

}
