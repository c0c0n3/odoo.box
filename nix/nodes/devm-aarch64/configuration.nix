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
    vault = {
      snakeoil.enable = true;

      # NOTE (1)
      # age = {
      #   root-pwd = ./vault/passwords/root.yesc.age;
      #   admin-pwd = ./vault/passwords/admin.yesc.age;
      #   odoo-admin-pwd = ./vault/passwords/odoo-admin.age;
      #   nginx-cert = ./vault/certs/localhost-cert.pem.age;
      #   nginx-cert-key = ./vault/certs/localhost-key.pem.age;
      # };
      # agez.enable = true;
      # agenix.enable = true;

      # NOTE (2)
      # root-ssh-file = ./vault/ssh/id_ed25519.pub;
      # admin-ssh-file = ./vault/ssh/id_ed25519.pub;
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
#
