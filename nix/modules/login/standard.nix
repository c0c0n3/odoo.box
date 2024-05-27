#
# Standard login mode implementation.
#
{ config, lib, pkgs, ... }:

{

  config = let
    mode = config.odbox.login.mode;
    admin-usr = config.odbox.login.admin-username;
    admin-pwd = config.odbox.vault.admin-pwd-file;
    admin-ssh = config.odbox.vault.admin-ssh-file;
    root-pwd = config.odbox.vault.root-pwd-file;
    root-ssh = config.odbox.vault.root-ssh-file;
    maybe = key: if key == null then [] else [ key ];
  in (lib.mkIf (mode == "standard") {

    # Set admin user's password and SSH login key if one was given.
    # Also set the given root password and root's SSH key if one was
    # specified.
    users.users."${admin-usr}" = {
      hashedPasswordFile = admin-pwd;
      openssh.authorizedKeys.keyFiles = maybe admin-ssh;
    };
    users.users.root = {
      hashedPasswordFile = root-pwd;
      openssh.authorizedKeys.keyFiles = maybe root-ssh;
    };

    # Let root log in through SSH with a password.
    services.openssh.settings = {
      PermitRootLogin = lib.mkForce "yes";                     # (1)
    };

  });

}
# NOTE
# ----
# 1. SSH root access. We only need it for remote deployments through
# `nixos-rebuild`. In theory we don't actually need this b/c we could
# ask `nixos-rebuild` to use `sudo` instead of logging in as root (see
# the `--use-remote-sudo` flag), but in practice support for `sudo` is
# kinda flaky at the moment---it definitely didn't work for me, despite
# the various workarounds suggested on the interwebs.
# See:
# - https://discourse.nixos.org/t/remote-nixos-rebuild-sudo-askpass-problem
#
# As a slight improvement, we could configure SSH to only let in root
# through a password-less login with an SSH key. (Set `PermitRootLogin`
# to `prohibit-password`.) But for now we'd like to keep the convenience.
# Notice we've got to use `mkForce` because the AWS image expression sets
# `PermitRootLogin` to `prohibit-password`:
# - https://github.com/NixOS/nixpkgs/blob/nixos-23.11/nixos/modules/virtualisation/amazon-image.nix#L84
# Since we'd also like to run on EC2 and to do that we need to import the
# AWS image expression, we've got to force our setting to stop Nix from
# moaning about
# > The option `services.openssh.settings.PermitRootLogin' has conflicting
# > definition values
#
