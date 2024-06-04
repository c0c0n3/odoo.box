#
# Generate the Odoo config file.
# Specify your admin password, Postgres DB name, and number of CPUs
# available to the Odoo service.
#
# TODO email!!
#
{ pkgs, odoo-db, cpus }:
let
  ini = pkgs.formats.ini {};
  config = {
    options = {                                                # (1)
      db_name = odoo-db;
      dbfilter = ".*";

      proxy_mode = true;

      limit_time_cpu = 600;
      limit_time_real = 1200;

      max_cron_threads = 1;
      workers = cpus * 2 + 1;                                  # (2)

      log_handler = ":INFO";
    };
  };
in
  ini.generate "odoo.cfg" config

# NOTE
# ----
# 1. Admin password. Never put the admin password here, e.g.
#     admin_passwd = "my secret";
# since the actual ini file gets generated in the Nix store.
# The function to generate the Odoo systemd entry (`odoo-svc.nix`)
# takes care of the password, making sure it won't wind up in the
# Nix store.
#
# 2. Performance. See:
# - https://www.odoo.com/documentation/14.0/administration/install/deploy.html#id5
#
# 3. Log level. To make Odoo spill its guts, set the log handler to
# ":DEBUG".
