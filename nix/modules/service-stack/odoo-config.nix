#
# Generate the Odoo config file.
# Specify your admin password, Postgres DB name, and number of CPUs
# available to the Odoo service.
#
# TODO email!!
#
{ pkgs, admin-pwd, db-name, cpus }:
let
  ini = pkgs.formats.ini {};
  config = {
    options = {
      admin_passwd = admin-pwd;

      db_name = db-name;
      dbfilter = ".*";

      proxy_mode = true;

      limit_time_cpu = 600;
      limit_time_real = 1200;

      max_cron_threads = 1;
      workers = cpus * 2 + 1;                                  # (1)
    };
  };
in
  ini.generate "odoo.cfg" config

# NOTE
# 1. Performance. See:
# - https://www.odoo.com/documentation/14.0/administration/install/deploy.html#id5
#
