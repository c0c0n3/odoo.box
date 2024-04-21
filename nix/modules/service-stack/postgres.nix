# Start Postgres and create a DB user with the same username as
# the Odoo system user. This way the Odoo service, which runs
# under the Odoo system user, can connect to Postgres on the
# Unix socket. Notice we don't create an Odoo DB since most
# likely you'd want to import your own.
{
    odoo-user
}:
{
  enable = true;
  ensureUsers = [{
    name = odoo-user;
  }];
}
