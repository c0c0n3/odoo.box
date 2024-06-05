#
# NixOS config to define the EC2 VM.
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
