#
# Write the command to run our DB init script.
#
{
  pkgs,
  admin-usr, odoo-usr, odoo-db, pgadmin-usr, pgadmin-db
}:
let
  roles-n-dbs = "${pkgs.odbox.db-init}/sql/roles-n-dbs.sql";
in
''
psql postgresql:/// -f ${roles-n-dbs} \
     --set=admin_role='${admin-usr}' \
     --set=odoo_role='${odoo-usr}' --set=odoo_db='${odoo-db}' \
     --set=pgadmin_role='${pgadmin-usr}' --set=pgadmin_db='${pgadmin-db}'
''
