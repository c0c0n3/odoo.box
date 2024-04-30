#
# Make the Bash backup script.
#
{
  # The name of the Odoo user.
  odoo-usr,
  # The name of the Odoo DB.
  odoo-db,
  # Absolute path to the backup base dir.
  basedir,
  # Delete all Odoo sessions stored on disk?
  clean-sessions ? false
}:
let
  dst-basedir = "${basedir}/odoo";
  src-filestore = "/var/lib/${odoo-usr}/data/filestore";
  src-sessions = "/var/lib/${odoo-usr}/data/sessions";
  dst-db-dump = "${dst-basedir}/${odoo-db}.dump.sql";
in ''
  umask 0077

  mkdir -p '${dst-basedir}'

  rm -f '${dst-db-dump}'
  sudo -u '${odoo-usr}' \
      pg_dump -U '${odoo-usr}' -O -n public '${odoo-db}' \
          > '${dst-db-dump}'

  rsync -av --delete '${src-filestore}' '${dst-basedir}/'

  ${if clean-sessions then "rm -rf '${src-sessions}'" else ""}
''
# NOTE
# ----
# 1. File perms. We `umask` w/ `0077` to make sure that only the
# user who runs this script can access the backup files. (Typically
# the user is root.)
# 2. DB dump. Notice we extract the dump under the Odoo user but
# then the actual dump file in the backup dir ends up being owned
# by the user who runs the script, typically root. So the `umask`
# in (1) also applies to the dump file.
# 3. Sessions dir. We zap it as Odoo will recreate it automatically.
#
