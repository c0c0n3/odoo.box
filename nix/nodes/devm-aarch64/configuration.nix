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
    vault.snakeoil.enable = true;
    # NOTE (1)
    # vault.age = {
    #   root-pwd = ./sec/generated/passwords/root.sha512.age;
    #   admin-pwd = ./sec/generated/passwords/admin.sha512.age;
    #   odoo-admin-pwd = ./sec/generated/passwords/odoo-admin.age;
    #   nginx-cert = ./sec/generated/certs/localhost-cert.pem.age;
    #   nginx-cert-key = ./sec/generated/certs/localhost-key.pem.age;
    # };
    # vault.agez.enable = true;
    # vault.agenix.enable = true;
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
# $ cd nodes/devm-aarch64/sec/
# $ vaultgen
#   # make script generate everything, skip prod certs step
# $ scp generated/age.key root@localhost:/etc/
# $ git add generated
# $ nixos-rebuild switch --fast --flake .#devm --target-host root@localhost --build-host root@localhost
# $ git restore --staged generated
#
