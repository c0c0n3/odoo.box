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

  odbox.server.enable = true;
  # odbox.service-stack.bootstrap-mode = true;
  odbox.swapfile = {
    enable = true;
    size = 8192;
  };
}
