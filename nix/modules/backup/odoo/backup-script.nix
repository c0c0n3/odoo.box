#
# Make the Bash backup script.
#
{
  # Config constants---service/user/db names, file paths, etc.
  const
}:
''
  umask 0077

  mkdir -p '${const.backup-dir}'

  rm -f '${const.db-dump}'
  sudo -u '${const.odoo-usr}' \
      pg_dump -U '${const.odoo-usr}' -O -n public '${const.odoo-db}' \
          > '${const.db-dump}'

  rsync -av --delete '${const.live-filestore}' '${const.backup-dir}/'
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
#
