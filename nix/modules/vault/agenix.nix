#
# See `docs.md` for module documentation.
#
{ config, lib, pkgs, ... }:

with lib;
with types;

{
  options = {
    odbox.vault.agenix.enable = mkOption {
      type = bool;
      default = false;
      description = ''
        Enable it to source vault secrets from Age-encrypted files.
      '';
    };
    odbox.vault.agenix.key = mkOption {
      type = nullOr nonEmptyStr;
      default = "/etc/age.key";
      description = ''
        Path to the Age key to use for decrypting secrets. This must
        be the private key whose public part was used to encrypt the
        secrets and must be deployed to the target machine beforehand.
        Also, the path to the key on the target machine must sit on a
        filesystem that's mounted at boot time (possibly using
        `neededForBoot`) or in any case be available right after
        the `specialfs` activation script runs.

        Set this to `null` to make Agenix use whatever is set in
        `age.identityPaths` or its default value if it's not been
        set.
      '';
    };
  };

  config = let
    enabled = config.odbox.vault.agenix.enable;
    key = config.odbox.vault.agenix.key;
  in (mkIf enabled
  {
    age = {
      identityPaths = mkIf (key != null) [ key ];
      secrets = {
        root-pwd.file = config.odbox.vault.age.root-pwd;
        admin-pwd.file = config.odbox.vault.age.admin-pwd;
        odoo-admin-pwd = {
          file = config.odbox.vault.age.odoo-admin-pwd;
          owner = "odoo";
          group = "odoo";
        };
        nginx-cert = {
          file = config.odbox.vault.age.nginx-cert;
          owner = "nginx";
          group = "nginx";
        };
        nginx-cert-key = {
          file = config.odbox.vault.age.nginx-cert-key;
          owner = "nginx";
          group = "nginx";
        };
      };
    };
    odbox.vault = {
      root-pwd-file = config.age.secrets.root-pwd.path;
      admin-pwd-file = config.age.secrets.admin-pwd.path;
      odoo-admin-pwd-file = config.age.secrets.odoo-admin-pwd.path;
      nginx-cert = config.age.secrets.nginx-cert.path;
      nginx-cert-key = config.age.secrets.nginx-cert-key.path;
    };
  });
}