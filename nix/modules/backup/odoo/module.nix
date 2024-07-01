#
# Implementation of the Odoo backup functionality declared in the
# interface.
# We set up systemd timers and services to run hot and cold backups.
# We use `pg_dump` to extract DB defs and data, whereas `rsync` takes
# care of syncing the file store to the backup area. Plus, we've got
# a restore service to take the backup DB dump and file store and turn
# them into the live Odoo DB and file store, respectively.
#
{ config, lib, pkgs, ... }:

with lib;

{
  config = let
    # Feature flag.
    enabled = config.odbox.backup.odoo.enable;

    # Service builder functions.
    mk-backup-svc = import ./mk-backup-svc.nix;
    mk-restore-svc = import ./mk-restore-svc.nix;
  in (mkIf enabled
  {
    systemd.services.odoo-hot-backup = mk-backup-svc {
      inherit config pkgs;
      hot = true;
    };
    systemd.services.odoo-cold-backup = mk-backup-svc {
      inherit config pkgs;
      hot = false;
    };
    systemd.services.odoo-restore-backup = mk-restore-svc {
      inherit config pkgs;
    };
  });
}
