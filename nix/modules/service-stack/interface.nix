#
# See `docs.md` for module documentation.
#
{ config, lib, pkgs, ... }:

with lib;
with types;

{
  options = {
    odbox.service-stack = {
      enable = mkOption {
        type = bool;
        default = false;
        description = ''
          Enable it to install the Odoo service stack.
          The stack is made of a fronting Nginx reverse proxy,
          the Odoo Web service and the Postgres DB backend.
          Plus, you can turn on PgAdmin separately if you'd also
          like to have secure access to the Odoo DB through a Web
          UI.
        '';
      };
      domain = mkOption {
        type = str;
        default = "localhost";
        description = ''
          Odoo domain name for Nginx's virtual host.
          Since we make the Odoo host the default Nginx server, you won't
          need to set this option unless you'd like to use NixOS's built-in
          support to automatically get and renew TLS certs, in which case,
          you should set this option to the FQDN of the host machine.
        '';
      };
      autocerts = mkOption {
        type = bool;
        default = false;
        description = ''
          If true, automatically acquire and renew Ngnix TLS certs from
          Let's Encrypt. Notice for this to work you've got to set the
          `odbox.service-stack.domain` option to the FQDN of the host
          machine.
        '';
      };
      bootstrap-mode = mkOption {
        type = bool;
        default = false;
        description = ''
          If true, install all the goodies in the the Odoo service
          stack except for actually running the Odoo server. The Odoo
          user and service will be there as well as the `odoo` binary,
          but the server won't run. This is useful if you want to
          bootstrap your Odoo DB and file store yourself—think migrating
          data from another Odoo server. In fact, it's not a good idea to
          have Odoo kick around while you bootstrap its data as experience
          has shown.
          Setting this option to false (the default) makes all the other
          options work normally—i.e. if you enable the stack, everything
          gets installed and runs as you'd expect.
        '';
      };
      odoo-package = mkOption {
        type = package;
        default = pkgs.odbox.odoo-14;
        description = "Odoo package to use.";
      };
      odoo-addons = mkOption {
        type = listOf package;
        default = [ pkgs.odbox.odoo-addons ];
        description = ''
          Nix-packaged Odoo addons to include in the Odoo server.
        '';
      };
      odoo-username = mkOption {
        type = str;
        default = "odoo";
        description = "Name of the Odoo system user.";
      };
      odoo-db-name = mkOption {
        type = str;
        default = "odoo";
        description = "Name of the Odoo Postgres DB.";
      };
      odoo-cpus = mkOption {
        type = ints.positive;
        default = 1;
        description = "Number of CPUs available to run the Odoo server.";
      };
      odoo-session-timeout = mkOption {
        type = ints.positive;
        default =  5;
        description = ''
          Login session timeout in minutes. Any session inactive for longer
          than these many minutes gets deleted and the user is forced to log
          in again.
        '';
      };
      pgadmin-enable = mkOption {
        type = bool;
        default = false;
        description = ''
          Also enable PgAdmin in addition to the other services
          in our service stack. This way you can read and write
          Odoo tables (but do nothing else) through the PgAdmin
          Web UI.
        '';
      };
      pgadmin-package = mkOption {
        type = package;
        default = pkgs.pgadmin4;
        description = "PgAdmin package to use.";
      };
      pgadmin-username = mkOption {
        type = str;
        default = "pgadmin";
        description = "Name of the PgAdmin system user.";
      };
      pgadmin-db-name = mkOption {
        type = str;
        default = "pgadmin";
        description = "Name of the PgAdmin Postgres DB.";
      };
      pgadmin-admin-email = mkOption {
        type = str;
        default = "admin@lo.kl";
        description = "Email address of the PgAdmin Web UI admin user.";
      };
    };
  };
}
