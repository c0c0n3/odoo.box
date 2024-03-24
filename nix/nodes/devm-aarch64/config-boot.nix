#
# NixOS config to define the Dev VM.
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
