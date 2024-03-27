#
# Tools to develop "odoo.box".
#
{ pkgs }:
with pkgs;
{
    all = [
        age
        agenix
        awscli2
        nixos-rebuild
        openssl
        poetry
        postgresql
        python3
        qemu
    ];
}
