#
# Make the systemd service entry for hot and cold backups.
#
{ config, pkgs, hot ? true }:
let
  # User, DB, service names and schedules.
  odoo-usr = config.odbox.service-stack.odoo-username;
  odoo-db = config.odbox.service-stack.odoo-db-name;
  odoo-svc = odoo-usr;                                         # (1)
  schedule = if hot
             then config.odbox.backup.odoo.hot-schedule
             else config.odbox.backup.odoo.cold-schedule;

  # Packages.
  sudo = pkgs.sudo;
  postgres = config.services.postgresql.package;
  rsync = pkgs.rsync;

  # Backup type and base dir.
  basedir = config.odbox.backup.basedir;
  kind = if hot then "hot" else "cold";
in {
  description = "Odoo DB and file store ${kind} backup to ${basedir}";

  requires = [ "postgresql.service" ];

  path = [ sudo postgres rsync ];

  preStart = if hot
             then ""
             else "systemctl stop ${odoo-svc}";

  script = import ./backup-script.nix {
    inherit odoo-usr odoo-db basedir;
    clean-sessions = !hot;
  };

  postStop = if hot
             then ""
             else "systemctl start ${odoo-svc}";

  serviceConfig = {
    Type = "oneshot";
    User = "root";
  };

  startAt = schedule;
}
# NOTE
# ----
# 1. Odoo service name. The service stack module makes the Odoo service
# name the same as the username specified through the module's interface
# option.
