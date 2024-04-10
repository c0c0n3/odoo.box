#
# NixOS config to define the EC2 VM:
# - public FQDN: ec2-54-76-182-114.eu-west-1.compute.amazonaws.com
# - hostname: ip-172-31-3-69.eu-west-1.compute.internal
#
# Notice this is the main config with the full Odoo service stack.
#
{ config, modulesPath, pkgs, ... }:
{
  imports = [ "${modulesPath}/virtualisation/amazon-image.nix" ];
  ec2.efi = true;

  time.timeZone = "Europe/Amsterdam";
  system.stateVersion = "23.11";


  odbox = {
    server.enable = true;
    vault = {
      snakeoil.enable = true;

      # age = {
      #   root-pwd = ./generated/passwords/root.yesc.age;
      #   admin-pwd = ./generated/passwords/admin.yesc.age;
      #   odoo-admin-pwd = ./generated/passwords/odoo-admin.age;
      #   nginx-cert = ./generated/certs/localhost-cert.pem.age;
      #   nginx-cert-key = ./generated/certs/localhost-key.pem.age;
      # };
      # agez.enable = true;
      # agenix.enable = true;

      root-ssh-file = ./id_rsa.pub;                            # (1)
      admin-ssh-file = ./id_rsa.pub;                           # (1)
    };
    service-stack.odoo-cpus = 4;
    swapfile = {
      enable = true;
      size = 16384;
    };
  };
}
# NOTE
# ----
# 1. SSH pub key. Copied from the one the NixOS AMI sets up from the EC2
# meta it fetches on boot. File:
# - /etc/ec2-metadata/public-keys-0-openssh-key
#