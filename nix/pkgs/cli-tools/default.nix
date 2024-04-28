{ pkgs, vaultgen, db-init }: import ./pkg.nix { inherit pkgs vaultgen db-init; }
