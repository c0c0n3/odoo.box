#
# Tools to develop "odoo.box".
#
{ pkgs }:
with pkgs;
{
    all = [
        age
        awscli2
        nixos-rebuild
        openssl
        poetry
        postgresql
        python3
        qemu
    ];
}
