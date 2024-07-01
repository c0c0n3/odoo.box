#
# Make the systemd service entry for restoring backups.
#
{ config, pkgs, ... }:
let
  # Config constants---service/user/db names, file paths, etc.
  const = import ./const.nix { inherit config; };

  # Packages.
  sudo = pkgs.sudo;
  postgres = config.services.postgresql.package;
  rsync = pkgs.rsync;
in {
  description = "Restore Odoo DB and file store from ${const.backup-dir}";

  path = [ sudo postgres rsync ];

  preStart = "systemctl stop ${const.odoo-svc}";

  script = import ./restore-script.nix {
    inherit const;
  };

  postStop = "systemctl start ${const.odoo-svc}";

  serviceConfig = {
    Type = "oneshot";
    User = "root";
  };
}
# NOTE
# ----
# 1. Manual start. We specify no timers, targets or other services
# that depend on this one. So systemd won't ever start this service.
# That's exactly what we want since the sysadmin should carry out the
# restore procedure manually, first by restoring the backup disk and
# then by running this service with
#
#     $ sudo systemctl start odoo-restore-backup
#
# 2. Postgres dependency. The restore script needs Postgres to be up
# and running so it can drop the Odoo DB before attempting to restore
# it. Then it restarts the Postgres service to make sure our init script
# (see service stack module) recreates the Odoo DB. Cool. Why not make
# the systemd service require Postgres? i.e. why not add this to the
# service definition:
#
#     requires = [ "postgresql.service" ];
#
# B/c then restarting Postgres from within the script will fail with
#
#     Main process exited, code=killed, status=15/TERM
#
# which makes sense since we'd be telling systemd to make sure Postgres
# is running but then at the same time we stop it.
#
