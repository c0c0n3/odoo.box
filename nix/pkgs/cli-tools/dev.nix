#
# Tools to develop "odoo.box".
#
{ pkgs, db-init, vaultgen }:
with pkgs;
{
    all = [
        age
        agenix
        awscli2
        db-init
        nixos-rebuild
        openssl
        poetry
        postgresql
        python3
        qemu
        vaultgen
    ];
}
