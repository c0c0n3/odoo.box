#
# NixOS config to define the EC2 VM:
# - public FQDN: ec2-54-76-182-114.eu-west-1.compute.amazonaws.com
# - hostname: ip-172-31-3-69.eu-west-1.compute.internal
#
# Notice this is the bootstrap config with the Odoo service stack
# configured in bootstrap mode.
#
{ config, pkgs, ... }:
{
  imports = [
    ./configuration.nix
  ];

  odbox.service-stack.bootstrap-mode = true;
}
