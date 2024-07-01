#
# Make the systemd service entry for hot and cold backups.
#
{ config, pkgs, hot ? true }:
let
  # Config constants---service/user/db names, file paths, etc.
  const = import ./const.nix { inherit config; };

  # Backup schedules.
  schedule = if hot
             then config.odbox.backup.odoo.hot-schedule
             else config.odbox.backup.odoo.cold-schedule;

  # Packages.
  sudo = pkgs.sudo;
  postgres = config.services.postgresql.package;
  rsync = pkgs.rsync;

  # Backup type.
  kind = if hot then "hot" else "cold";
in {
  description = "Back up Odoo DB and file store ${kind} to ${const.backup-dir}";

  requires = [ "postgresql.service" ];

  path = [ sudo postgres rsync ];

  preStart = if hot
             then ""
             else "systemctl stop ${const.odoo-svc}";

  script = import ./backup-script.nix {
    inherit const;
  };

  postStop = if hot
             then ""
             else "systemctl start ${const.odoo-svc}";

  serviceConfig = {
    Type = "oneshot";
    User = "root";
  };

  startAt = schedule;
}
