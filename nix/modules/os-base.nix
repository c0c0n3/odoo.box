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
# - creating an admin user with username 'admin' and setting its password
#   to the hashed password specified through the vault module;
# - setting the root password to the hashed password specified through
#   the vault module.
#
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
    root-pwd = config.odbox.vault.root-pwd-file;
  in (mkIf enabled
  {
    # Enable Flakes.
    nix = {
      package = pkgs.nixFlakes;
      settings.experimental-features = [ "nix-command" "flakes" ];
    };

    # Install Emacs and make it the default editor system-wide.
    # Also install the given CLI toos and enable Bash completion.
    environment.systemPackages = [ pkgs.emacs-nox ] ++ tools;
    environment.variables = {
      EDITOR = "emacs";    # NOTE (1)
    };
    programs.bash.enableCompletion = true;

    # Only allow to change users and groups through NixOS config.
    users.mutableUsers = false;

    # Create admin user w/ name='admin' and given password.
    # Also set the given root password.
    users.users.admin = {
      isNormalUser = true;
      group = "users";
      extraGroups = [ "wheel" ];
      hashedPasswordFile = admin-pwd;
    };
    users.users.root.hashedPasswordFile = root-pwd;
  });

}
# NOTE
# ----
# 1. Command Paths. Should we use absolute paths to the Nix derivations?
# Seems kinda pointless b/c programs added to systemPackages will be in
# the PATH anyway...
