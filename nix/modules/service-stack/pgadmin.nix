{ }:
{
  enable = true;
  initialPasswordFile = "/var/lib/pgadmin/pwd.txt"; # "/tmp/pgadmin.pwd";
  initialEmail = "dumb@dumb.er";
  settings = {
    CONFIG_DATABASE_URI = "postgresql:///";
  };
}
