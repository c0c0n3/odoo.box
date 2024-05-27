#
# NixOS config to define the Dev VM.
# Notice this is the main config with the full Odoo service stack.
#
{ config, pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "devm";
  time.timeZone = "Europe/Amsterdam";
  system.stateVersion = "23.11";

  odbox = {
    server.enable = true;
    login.mode = "standard";    # NOTE (3)

    # NOTE (5)
    # service-stack.autocerts = true;
    # local-ca.enable = true;

    vault = {
      snakeoil.enable = true;

      # NOTE (1)
      # age = {
      #   root-pwd = ./vault/passwords/root.yesc.age;
      #   admin-pwd = ./vault/passwords/admin.yesc.age;
      #   odoo-admin-pwd = ./vault/passwords/odoo-admin.txt.age;
      #   pgadmin-admin-pwd = ./vault/passwords/pgadmin-admin.txt.age;
      #   nginx-cert = ./vault/certs/localhost-cert.pem.age;
      #   nginx-cert-key = ./vault/certs/localhost-key.pem.age;
      # };
      # agez.enable = true;
      # agenix.enable = true;

      # NOTE (2)
      # root-ssh-file = ./vault/ssh/id_ed25519.pub;
      # admin-ssh-file = ./vault/ssh/id_ed25519.pub;
    };

    backup = {
      basedir = "/backup";
      odoo = {
        enable = false;                                        # (4)
        hot-schedule = [ "14:50:00" ];
        cold-schedule = [ "14:57:00" ];
      };
    };

    swapfile = {
      enable = true;
      size = 8192;
    };
  };
}
# NOTE
# ----
# 1. Testing Age decryption. See the *Age Secrets* section of the
# *Vault and Login Configs* docs.
# 2. Testing SSH keys. See the *SSH Keys* section of the
# *Vault and Login Configs* docs.
# 3. Testing cloud login. See the *Cloud Login* section of the
# *Vault and Login Configs* docs.
# 4. Testing backups. Set the schedules you like and then enable
# the feature. Check service logs and backup dir after each run.
# 5. Testing ACME TLS certs. See `local-ca` module docs.
