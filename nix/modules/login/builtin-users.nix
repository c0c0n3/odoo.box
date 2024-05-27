#
# Unconditionally create our built-in users.
# At the moment the only built-in user is the admin user, which we
# grant super-cow powers by making it a member of wheel.
#
{ config, lib, pkgs, ... }:

{

  config = let
    admin-usr = config.odbox.login.admin-username;
  in {
    # Create the admin user but leave the setting of credentials
    # to the other login implementations.
    users.users."${admin-usr}" = {
      isNormalUser = true;
      group = "users";
      extraGroups = [ "wheel" ];
    };
  };

}
