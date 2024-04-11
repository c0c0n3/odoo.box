#
# NixOS config to define the on-demand EC2 Graviton VM.
# We tested this config works on: m6g.xlarge, m6g.2xlarge, c6g.xlarge,
# c6g.2xlarge, and t4g.2xlarge.
#
# Notice this is the main config with the full Odoo service stack.
#
{ config, modulesPath, pkgs, ... }:
{
  imports = [ "${modulesPath}/virtualisation/amazon-image.nix" ];
  ec2.efi = true;

  # The `amazon-image` module automatically sets the hostname from
  # dynamically retrieved EC2 metadata, so we leave it be. Those
  # EC2 hostnames all follow the same pattern:
  #     <addr>.<region>.compute.internal
  # e.g. `ip-172-31-3-61.eu-west-1.compute.internal`.
  time.timeZone = "Europe/Amsterdam";
  system.stateVersion = "23.11";


  odbox = {
    server.enable = true;
    vault = {
      snakeoil.enable = true;

      # age = {
      #   root-pwd = ./vault/passwords/root.yesc.age;
      #   admin-pwd = ./vault/passwords/admin.yesc.age;
      #   odoo-admin-pwd = ./vault/passwords/odoo-admin.age;
      #   nginx-cert = ./vault/certs/localhost-cert.pem.age;
      #   nginx-cert-key = ./vault/certs/localhost-key.pem.age;
      # };
      # agez.enable = true;
      # agenix.enable = true;

      root-ssh-file = ./vault/ssh/id_rsa.pub;                  # (1)
      admin-ssh-file = ./vault/ssh/id_rsa.pub;                 # (1)
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
