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
# 1. Testing Age decryption. First comment out the `vault.snakeoil`
# option and comment in the `vault.age` stanza. Then comment in
# either the `vault.agez` or `vault.agenix` option, depending on
# which module you want to test. After that
# $ cd odoo.box/nix
# $ nix shell
# $ cd nodes/devm-aarch64/
# $ vaultgen
#   # make script generate everything, skip prod certs step
# $ scp vault/age.key root@localhost:/etc/
# $ git add vault
# $ nixos-rebuild switch --fast --flake .#devm \
#       --target-host root@localhost --build-host root@localhost
# $ git restore --staged vault
#
# 2. Testing SSH keys. First comment in the `vault.root-ssh-file` and
# `vault.admin-ssh-file` options. Then
# $ cd odoo.box/nix
# $ nix shell
# $ cd nodes/devm-aarch64/
# $ vaultgen
#   # make script generate everything, skip prod certs step
# $ git add vault/ssh/id_ed25519.pub
# $ nixos-rebuild switch --fast --flake .#devm \
#       --target-host root@localhost --build-host root@localhost
# $ git restore --staged vault
# Now try logging in through SSH using the generated SSH identity:
# $ ssh root@localhost -i vault/ssh/id_ed25519
# $ ssh admin@localhost -i vault/ssh/id_ed25519
#
# 3. Testing cloud login. Comment out the `login.mode` option so you
# get the default login mode which is the cloud mode. Then follow the
# same procedure as in NOTE #2 above. Also, password logins (either at
# the TTY or through SSH) will fail. Finally, to get back to standard
# login mode, comment back in the `login.mode` option, comment out the
# `*-ssh-file` option, cd to the base `nix` dir and then redeploy using
# the current SSH identity:
# $ NIX_SSHOPTS='-i nodes/devm-aarch64/vault/ssh/id_ed25519' \
#   nixos-rebuild switch --fast --flake .#devm \
#       --target-host root@localhost --build-host root@localhost
#
