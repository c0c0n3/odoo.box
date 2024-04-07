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
    vault = {
      snakeoil.enable = true;

      # NOTE (1)
      # age = {
      #   root-pwd = ./generated/passwords/root.yesc.age;
      #   admin-pwd = ./generated/passwords/admin.yesc.age;
      #   odoo-admin-pwd = ./generated/passwords/odoo-admin.age;
      #   nginx-cert = ./generated/certs/localhost-cert.pem.age;
      #   nginx-cert-key = ./generated/certs/localhost-key.pem.age;
      # };
      # agez.enable = true;
      # agenix.enable = true;

      # NOTE (2)
      # root-ssh-file = ./generated/ssh/id_ed25519.pub;
      # admin-ssh-file = ./generated/ssh/id_ed25519.pub;
    };
    swapfile = {
      enable = true;
      size = 8192;
    };
  };
}
# NOTE
# ----
# 1. Testing Age decryption. First comment out the `vault.snakeoil`
# option and comment in the `vault.age` stanza. Then comment in
# either the `vault.agez` or `vault.agenix` option, depending on
# which module you want to test. After that
# $ cd odoo.box/nix
# $ nix shell
# $ cd nodes/devm-aarch64/
# $ vaultgen
#   # make script generate everything, skip prod certs step
# $ scp generated/age.key root@localhost:/etc/
# $ git add generated
# $ nixos-rebuild switch --fast --flake .#devm --target-host root@localhost --build-host root@localhost
# $ git restore --staged generated
#
# 2. Testing SSH keys. First comment in the `vault.root-ssh-file` and
# `vault.admin-ssh-file` options. Then
# $ cd odoo.box/nix
# $ nix shell
# $ cd nodes/devm-aarch64/
# $ vaultgen
#   # make script generate everything, skip prod certs step
# $ git add generated/ssh/id_ed25519.pub
# $ nixos-rebuild switch --fast --flake .#devm --target-host root@localhost --build-host root@localhost
# $ git restore --staged generated
# Now try logging in through SSH using the generated SSH identity:
# $ ssh root@localhost -i generated/ssh/id_ed25519
# $ ssh admin@localhost -i generated/ssh/id_ed25519
#
