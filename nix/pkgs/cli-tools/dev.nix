#
# Tools to develop "odoo.box".
#
{ pkgs }:
with pkgs;
{
    all = [
        awscli2
        nixos-rebuild
        python3
        qemu
    ];
}
