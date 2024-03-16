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
        postgresql
        python3
        qemu
    ];
}
