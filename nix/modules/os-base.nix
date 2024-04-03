#
# A simple system base with CLI tools, Emacs and admin user.
# This module installs:
#
# * Emacs (built w/o X11 deps)
# * Bash completion and a given set of CLI tools
# * Nix Flakes extension
#
# and then makes:
#
# * Emacs the default editor system-wide (`EDITOR` environment variable)
#
# Finally, this module configures users by
# - only allowing to change users and groups through NixOS config;
# - creating an admin (wheel) user with username 'admin' and setting its
#   password to the hashed password specified through the vault module;
# - setting the root password to the hashed password specified through
#   the vault module;
# - setting an SSH login key for the admin user if one was specified
#   through the vault module;
# - setting an SSH login key for the root user if one was specified
#   through the vault module;
# - letting wheel users run `sudo` without a password.
#
# Because wheel users don't have to enter a password to `sudo`, you
# could have wheel users without passwords if you wanted to. In this
# setup, a wheel user would be configured with an SSH key to log in
# but no system password. Obviously, this kind of arrangement works
# as long as those users only ever log in through SSH, which is why,
# as a sane default, we also set root and admin passwords.
{ config, lib, pkgs, ... }:

with lib;
with types;

{

  options = {
    odbox.base.enable = mkOption {
      type = bool;
      default = false;
      description = ''
        Enable it to install this system base.
      '';
    };
    odbox.base.cli-tools = mkOption {
      type = listOf package;
      default = [];
      description = ''
        CLI tools to install system-wide.
      '';
    };
  };

  config = let
    enabled = config.odbox.base.enable;
    tools = config.odbox.base.cli-tools;
    admin-pwd = config.odbox.vault.admin-pwd-file;
    admin-ssh = config.odbox.vault.admin-ssh-file;
    root-pwd = config.odbox.vault.root-pwd-file;
    root-ssh = config.odbox.vault.root-ssh-file;
    maybe = key: if key == null then [] else [key];
  in (mkIf enabled
  {
    # Enable Flakes.
    nix = {
      package = pkgs.nixFlakes;
      settings.experimental-features = [ "nix-command" "flakes" ];
    };

    # Install Emacs and make it the default editor system-wide.
    # Also install the given CLI tools and enable Bash completion.
    environment.systemPackages = [ pkgs.emacs-nox ] ++ tools;
    environment.variables = {
      EDITOR = "emacs";    # NOTE (1)
    };
    programs.bash.enableCompletion = true;

    # Only allow to change users and groups through NixOS config.
    users.mutableUsers = false;

    # Create admin user w/ name='admin', given password and SSH login
    # key if one was set. Also set the give root password and root's
    # SSH key of one was set.
    users.users.admin = {
      isNormalUser = true;
      group = "users";
      extraGroups = [ "wheel" ];
      hashedPasswordFile = admin-pwd;
      openssh.authorizedKeys.keyFiles = maybe admin-ssh;
    };
    users.users.root = {
      hashedPasswordFile = root-pwd;
      openssh.authorizedKeys.keyFiles = maybe root-ssh;
    };

    # Let wheel users run `sudo` without a password.
    security.sudo.wheelNeedsPassword = false;
  });
}
# NOTE
# ----
# 1. Command Paths. Should we use absolute paths to the Nix derivations?
# Seems kinda pointless b/c programs added to systemPackages will be in
# the PATH anyway...
