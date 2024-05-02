#
# See `docs.md` for module documentation.
#
{ config, lib, pkgs, ... }:

with lib;
with types;

{

  options = {
    odbox.login.mode = mkOption {
      type = enum [ "standard" "cloud" ];
      default = "cloud";
      description = ''
        This option lets you choose how the root and admin users can
        log in. In cloud mode, these users can only log in over SSH
        with their respective SSH identities. In standard mode, they
        can log in both through TTY and SSH using passwords. Plus, they
        can also log in over SSH using their respective identities if
        SSH keys are set in the vault.
      '';
    };
    odbox.login.admin-username = mkOption {
      type = str;
      default = "admin";
      description = ''
        The name of the sys admin user.
      '';
    };
  };

}
