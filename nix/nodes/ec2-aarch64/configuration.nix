#
# NixOS config to define the on-demand EC2 Graviton VM.
# We tested this config works on: m6g.xlarge, m6g.2xlarge, c6g.xlarge,
# c6g.2xlarge, and t4g.2xlarge.
#
# Notice this is the main config with the full Odoo service stack.
#
{ config, modulesPath, pkgs, ... }:
let
  backup-mount-dir = "/backup";
in {
  imports = [ "${modulesPath}/virtualisation/amazon-image.nix" ];
  ec2.efi = true;

  time.timeZone = "Europe/Amsterdam";
  system.stateVersion = "23.11";

  fileSystems."${backup-mount-dir}" = {
    device = "/dev/disk/by-partlabel/backup";                  # (3)
    fsType = "ext4";
  };

  odbox = {
    server.enable = true;
    backup = {
      basedir = backup-mount-dir;
      odoo = {
        enable = true;
        hot-schedule = [ "11:00:00" "14:00:00" "16:00:00" ];
        cold-schedule = [ "02:00:00" ];
      };
    };
    vault = {
      agez.enable = true;                                      # (4)
      age = {
        odoo-admin-pwd = ./vault/passwords/odoo-admin.txt.age;
        pgadmin-admin-pwd = ./vault/passwords/pgadmin-admin.txt.age;
      };
      root-ssh-file = ./vault/ssh/id_rsa.pub;                  # (1)
      admin-ssh-file = ./vault/ssh/id_rsa.pub;                 # (1)
    };
    login.admin-email = "sys-admin@martel-innovate.com";
    service-stack = {
      autocerts = true;
      domain = "test-odoo.martel-innovate.com";
      odoo-cpus = 4;
      odoo-session-timeout = 14 * 24 * 60;
    };
    swapfile = {
      enable = true;
      size = 32768;
    };
  };
}
# NOTE
# ----
# 1. SSH pub key. Copied from the one the NixOS AMI sets up from the EC2
# meta it fetches on boot. File:
# - /etc/ec2-metadata/public-keys-0-openssh-key
#
# 2. Hostname. The `amazon-image` module automatically sets the hostname
# from dynamically retrieved EC2 metadata, so we leave it be. Those EC2
# hostnames all follow the same pattern:
#     <addr>.<region>.compute.internal
# e.g. `ip-172-31-3-61.eu-west-1.compute.internal`.
#
# 3. Backup disk. We use GPT partition names to reliably find the backup
# disk. This works because we can control what those names are and we can
# keep them unique across disks and partitions. The advantage of using a
# GTP partition name over a UUID is that if we replace the disk with a
# new one or migrate to another VM, our Nix config won't need to change,
# provided we always set up a GTP partition named `backup`.
# See:
# - Our EC2 bootstrap procedure
# - https://wiki.archlinux.org/title/persistent_block_device_naming
#
# 4. Age key. Don't forget to upload it to `/etc/` the first time you
# deploy or if you ever generate a new one.
# See:
# - Our EC2 bootstrap procedure
# - Our docs about Age secrets
