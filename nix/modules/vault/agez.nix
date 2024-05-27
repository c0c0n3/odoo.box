#
# See `docs.md` for module documentation.
#
{ config, lib, pkgs, ... }:

with lib;
with types;

{
  options = {
    odbox.vault.agez.enable = mkOption {
      type = bool;
      default = false;
      description = ''
        Enable it to source vault secrets from Age-encrypted files.
      '';
    };
    odbox.vault.agez.key = mkOption {
      type = nonEmptyStr;
      default = "/etc/age.key";
      description = ''
        Path to the Age key to use for decrypting secrets. This must
        be the private key whose public part was used to encrypt the
        secrets and must be deployed to the target machine beforehand.
        Also, the path to the key on the target machine must sit on a
        filesystem that's mounted at boot time (possibly using
        `neededForBoot`) or in any case be available right after
        the `specialfs` activation script runs.
      '';
    };
    odbox.vault.agez.dir = mkOption {
      type = str;
      default = "/run/agez";
      description = ''
        Path to the base directory where to decrypt files. Ideally it
        should sit on a `tmpfs` filesystem so decrypted files get written
        to RAM instead of disk. Also, regardless of its type, the filesystem
        in question should be mounted on boot (possibly using `neededForBoot)
        or in any case be available right after the `specialfs` activation
        script runs.
      '';
    };
  };

  config = let
    # Feature flags.
    enabled = config.odbox.vault.agez.enable;
    has-autocerts = config.odbox.service-stack.autocerts;
    has-pgadmin = config.odbox.service-stack.pgadmin-enable;

    # Users and groups.
    odoo = config.odbox.service-stack.odoo-username;
    pgadmin = config.odbox.service-stack.pgadmin-username;
    nginx = config.users.users.nginx.name;

    # Activation lib.
    dir = config.odbox.vault.agez.dir;
    activation = import ./agez-activation-lib.nix {
      inherit config pkgs lib;
    };

    # Age files.
    root = {
      encryptedFile = config.odbox.vault.age.root-pwd;
      decryptedFile = "${dir}/passwords/root.hash";
    };
    admin = {
      encryptedFile = config.odbox.vault.age.admin-pwd;
      decryptedFile = "${dir}/passwords/admin.hash";
    };
    odoo-admin = {
      encryptedFile = config.odbox.vault.age.odoo-admin-pwd;
      decryptedFile = "${dir}/passwords/odoo-admin.txt";
      user = odoo;
      group = odoo;
    };
    pgadmin-admin = {
      encryptedFile = config.odbox.vault.age.pgadmin-admin-pwd;
      decryptedFile = "${dir}/passwords/pgadmin-admin.txt";
      user = pgadmin;
      group = pgadmin;
    };
    cert = {
      encryptedFile = config.odbox.vault.age.nginx-cert;
      decryptedFile = "${dir}/certs/nginx-cert.pem";
      user = nginx;
      group = nginx;
    };
    cert-key = {
      encryptedFile = config.odbox.vault.age.nginx-cert-key;
      decryptedFile = "${dir}/certs/nginx-cert-key.pem";
      user = nginx;
      group = nginx;
    };
    addIf = cond: x: if cond then [ x ] else [];
    ageFiles = [ odoo-admin ]
            ++ addIf (root.encryptedFile != null) root
            ++ addIf (admin.encryptedFile != null) admin
            ++ addIf (!has-autocerts) cert
            ++ addIf (!has-autocerts) cert-key
            ++ addIf has-pgadmin pgadmin-admin
            ;
  in (mkIf enabled
  {
    odbox.vault = {
      root-pwd-file = root.decryptedFile;
      admin-pwd-file = admin.decryptedFile;
      odoo-admin-pwd-file = odoo-admin.decryptedFile;
      pgadmin-admin-pwd-file = pgadmin-admin.decryptedFile;
      nginx-cert = cert.decryptedFile;
      nginx-cert-key = cert-key.decryptedFile;
    };
    system.activationScripts.age-start = {
      text = activation.makeDecryptionScript ageFiles;
      deps = [ "specialfs" ];
    };
    system.activationScripts.age-end = {
      text = activation.makeAssignmentScript ageFiles;
      deps = [ "age-start" "users" "groups" ];
    };
  });
}
