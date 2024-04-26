# TODO docs
# Run PgAdmin with a built-in connection to the Odoo DB and only
# R/W perms on Odoo tables, plus read access to Postgres stats.
{ config, lib, pkgs, ... }:

with lib;

{

  config = let
    enabled = config.odbox.service-stack.enable &&
              config.odbox.service-stack.pgadmin-enable;

    # Username, DB name and connection string.
    pgadmin-usr = config.odbox.service-stack.pgadmin-username;
    pgadmin-db = config.odbox.service-stack.pgadmin-db-name;
    pgadmin-db-uri = "postgresql:///${pgadmin-db}";

    # Packages.
    postgres-pkg = config.services.postgresql.package;
    pgadmin-pkg = config.odbox.service-stack.pgadmin-package;

    # Commands.
    pgadmin-boot = "${pkgs.odbox.db-init}/bin/pgadmin-boot";

  in (mkIf enabled
  {
    users.users."${pgadmin-usr}" = {
      isSystemUser = true;
      group = pgadmin-usr;
    };
    users.groups."${pgadmin-usr}"= { };

    environment.etc."pgadmin/config_system.py" = {
      text = ''
        SERVER_MODE = True
        DEFAULT_SERVER_PORT = 5050
        CONFIG_DATABASE_URI = "${pgadmin-db-uri}"
      '';
      mode = "0600";
      user = pgadmin-usr;
      group = pgadmin-usr;
    };

    systemd.services.pgadmin-setup = {
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" "postgresql.service" ];
      requires = [ "network.target" "postgresql.service" ];

      path = [ pgadmin-pkg postgres-pkg ];

      restartTriggers = [
        "/etc/pgadmin/config_system.py"
        # TODO add password file
      ];

      serviceConfig = {
        User = pgadmin-usr;
        DynamicUser = true;
        LogsDirectory = pgadmin-usr;
        StateDirectory = pgadmin-usr;
        ExecStart = ''
          ${pgadmin-boot} dumb@dumb.er /var/lib/pgadmin/pwd.txt \
              ${escapeShellArg pgadmin-db-uri}
        '';
      };
    };
  });

}
