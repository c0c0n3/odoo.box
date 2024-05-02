#
# Cloud login mode implementation.
#
{ config, lib, pkgs, ... }:

{

  config = let
    mode = config.odbox.login.mode;
    admin-usr = config.odbox.login.admin-username;
    admin-ssh = config.odbox.vault.admin-ssh-file;
    root-ssh = config.odbox.vault.root-ssh-file;
    require = file: assert file != null; [ file ];
  in (lib.mkIf (mode == "cloud") {

    # Make root and admin accounts password-less and only allow them
    # to log in over SSH with their respective SSH identities.
    users.users."${admin-usr}" = {
      hashedPassword = "!";                                    # (1)
      openssh.authorizedKeys.keyFiles = require admin-ssh;     # (2)
    };
    users.users.root = {
      hashedPassword = "!";                                    # (1)
      openssh.authorizedKeys.keyFiles = require root-ssh;      # (2)
    };

    # Disable password login through SSH or any other form of SSH
    # keyboard-interactive authentication.
    services.openssh.settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };

  });

}
# NOTE
# ----
# 1. Disabling admin and root password login. This works because no
# hashed password will ever match "!", so these users won't be able
# to log in with a password.
# See:
# - https://discourse.nixos.org/t/how-to-disable-root-user-account-in-configuration-nix/13235
#
# 2. Lockout sanity check. If there's no SSH keys, then you get locked
# out of the target machine. This is because we set bogus passwords (1)
# and so there's no way you can get in without an SSH key. Now NixOS
# has a similar sanity check where it stops evaluation if it detects
# a lockout situation and warns you about with the following message:
# > Neither the root account nor any wheel user has a password
# > or SSH authorized key. You must set one to prevent being
# > locked out of your system.
# But b/c we set a password, the built-in NixOS check won't work for
# us.
#