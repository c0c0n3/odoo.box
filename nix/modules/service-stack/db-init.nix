#
# Write the command to run our DB init script.
#
{
  odoo-usr, odoo-db, pgadmin-usr, pgadmin-db
}:
let
  script = ./db-init.sql;
in
''
psql postgresql:/// -f ${script} \
     --set=odoo_role='${odoo-usr}' --set=odoo_db='${odoo-db}' \
     --set=pgadmin_role='${pgadmin-usr}' --set=pgadmin_db='${pgadmin-db}'
''
