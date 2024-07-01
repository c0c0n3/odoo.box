#
# Make the Bash restore script.
# Assumptions:
# - root runs this script
# - Postgres is up and running when the script starts
#
{
  # Config constants---service/user/db names, file paths, etc.
  const
}:
''
  # Stop as soon as something fails, even in a pipeline.
  # Also print each command after expanding variables.
  set -ueo pipefail
  set -x

  # Drop the Odoo DB if it exists, then recreate an empty one and finally
  # restore it. (Our Postgres init script creates an empty DB.)
  sudo -u '${const.postgres-usr}' \
    psql -c 'DROP DATABASE ${const.odoo-db} WITH (FORCE);' || true
  systemctl restart '${const.postgres-svc}'
  cat '${const.db-dump}' | \
    sudo -u '${const.odoo-usr}' psql -d '${const.odoo-db}' -f -

  # Restore the Odoo file store from the backup one.
  mkdir -p '${const.live-filestore}'
  rsync -av --delete '${const.backup-filestore}/' '${const.live-filestore}/'
''
# NOTE
# ----
# 1. Resilience. This script should **always** be able to pick up from
# where it left off. This is important b/c systemd re-runs the script
# on failure, even if the service type is one-shot.
# 2. Backup consistency. This script should **always** treat the whole
# backup dir as read-only. It should never ever change anything in there!
#
