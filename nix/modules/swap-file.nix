#
# TODO. Licence.
# Code copied over from github.com/c0c0n3/trixie-dotses. Is it going to be
# an issue?
#

#
# Enable swapping on a swap file.
# The default file is `/swapfile` and has a size of 4 GiB.
# Under the hood, we automatically tweak kernel parameters for "swappiness".
#
{ config, pkgs, lib, ... }:

with lib;
with types;
{

  options = {
    odbox.swapfile.enable = mkOption {
      type = bool;
      default = false;
      description = ''
        Enables using a swap file.
      '';
    };
    odbox.swapfile.pathname = mkOption {
      type = str;
      default = "/swapfile";
      description = ''
        Path to the swap file.
      '';
    };
    odbox.swapfile.size = mkOption {
      type = int;
      default = 4096;
      description = ''
        The size, in MiB, of the swap file.
      '';
    };
  };

  config = let
    enabled = config.odbox.swapfile.enable;
    file = config.odbox.swapfile.pathname;
    sz = config.odbox.swapfile.size;
  in
  {

    swapDevices = mkIf enabled [{
      device = file;
      size = sz;
    }];

    boot.kernel.sysctl = mkIf enabled {
      "vm.swappiness" = 1;
      "vm.vfs_cache_pressure" = 50;
    };

  };

}