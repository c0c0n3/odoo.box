#
# Generate the systemd entry for the Odoo service.
# Notice we require a separate password file containing the Odoo admin
# password to avoid the password winding up in the Nix store. Typically
# the password file is mounted on `/run` and its content extracted from
# an encrypted file in the Nix store. Sadly Odoo can't read its own
# password from a separate file, so we have no other option than generate
# a new config file with the Nix-generated config plus the admin password.
# This merged configuration sits in the Odoo service dir and is only
# accessible to the Odoo system user.
#
{
  # Nixpkgs lib.
  lib,
  # Odoo system username.
  username,
  # Postgres package where Odoo can get `psql` from.
  postgres-pkg,
  # Odoo package to use.
  odoo-pkg,
  # List of packages containing Odoo addons to link into the server.
  # Pass an empty list if you have no addons.
  addons,
  # Odoo config file in the Nix store. Must not include the admin pass.
  cfg-file,
  # File containing the clear-text Odoo admin pass.
  # Typically this is mounted on `/run` after extracting it from an
  # encrypted file.
  pwd-file,
  # Whether to start the Odoo server (`false`) or just create the Odoo
  # system user and the file store dir.
  bootstrap
}:
with lib;
let
  odoo-bin = "${odoo-pkg}/bin/odoo";
  addon-paths = concatMapStringsSep "," escapeShellArg addons;
  addons-opt = optionalString (addons != []) "--addons-path=${addon-paths}";
  data-dir = "$STATE_DIRECTORY/data";
  merged-config = "$STATE_DIRECTORY/config.ini";
  run = if bootstrap then
          "mkdir -p ${data-dir}/filestore"
        else
          ''
            export HOME=$STATE_DIRECTORY

            rm -f ${merged-config}
            cp ${cfg-file} ${merged-config}
            chmod 600 ${merged-config}
            echo "admin_passwd=$(cat ${pwd-file})" >> ${merged-config}

            ${odoo-bin} -c ${merged-config} -D ${data-dir} \
                --no-database-list ${addons-opt}
          '';
in {
  wantedBy = [ "multi-user.target" ];
  after = [ "network.target" "postgresql.service" ];

  # pg_dump
  path = [ postgres-pkg ];

  requires = [ "postgresql.service" ];
  script = run;

  serviceConfig = {
    DynamicUser = true;
    User = username;
    StateDirectory = username;
  };
}