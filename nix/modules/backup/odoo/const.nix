#
# Constants shared across the module implementation Nix expressions.
#
{ config }:
rec {
  # The name of the Postgres user.
  postgres-usr = config.services.postgresql.superUser;
  # The name of the Postgres service.
  postgres-svc = "postgresql";
  # The name of the Odoo user.
  odoo-usr = config.odbox.service-stack.odoo-username;
  # The name of the Odoo DB.
  odoo-db = config.odbox.service-stack.odoo-db-name;
  # The name of the Odoo service.
  odoo-svc = odoo-usr;                                         # (1)
  # Absolute path to the Odoo backup base dir.
  backup-dir = "${config.odbox.backup.basedir}/odoo";
  # Absolute path to the Odoo backup file store.
  backup-filestore = "${backup-dir}/filestore";
  # Absolute path to the Odoo service home dir.
  odoo-home = "/var/lib/${odoo-usr}";                          # (2)
  # Absolute path to the Odoo live file store.
  live-filestore = "${odoo-home}/data/filestore";
  # Absolute path to the Odoo DB dump file in the backup dir.
  db-dump = "${backup-dir}/${odoo-db}.dump.sql";
}
# NOTE
# ----
# 1. Odoo service name. The service stack module makes the Odoo service
# name the same as the username specified through the module's interface
# option.
# 2. Odoo home. The service stack module makes the Odoo home dir under
# the customary `/var/lib` using the Odoo user name as a dir name.
