#
# Tools to develop "odoo.box".
#
{ pkgs }:
with pkgs;
{
    all = [
        awscli2
        nixos-rebuild
        poetry
        python3
        qemu
    ];
}
