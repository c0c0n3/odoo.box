#
# Age-backed vault.
# Configure the vault with passwords and certificates extracted from
# Age-encrypted files.
#
# Typically you'd want to use `odbox.vault.agenix` instead of this
# module---see comments there about it.
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
    enabled = config.odbox.vault.agez.enable;
    dir = config.odbox.vault.agez.dir;
    activation = import ./agez-activation-lib.nix {
        inherit config pkgs lib;
    };

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
      user = "odoo";
      group = "odoo";
    };
    cert = {
      encryptedFile = config.odbox.vault.age.nginx-cert;
      decryptedFile = "${dir}/certs/nginx-cert.pem";
      user = "nginx";
      group = "nginx";
    };
    cert-key = {
      encryptedFile = config.odbox.vault.age.nginx-cert-key;
      decryptedFile = "${dir}/certs/nginx-cert-key.pem";
      user = "nginx";
      group = "nginx";
    };
    ageFiles = [ root admin odoo-admin cert cert-key ];
  in (mkIf enabled
  {
    odbox.vault = {
      root-pwd-file = root.decryptedFile;
      admin-pwd-file = admin.decryptedFile;
      odoo-admin-pwd-file = odoo-admin.decryptedFile;
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