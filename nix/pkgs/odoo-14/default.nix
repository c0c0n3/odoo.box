{ system, pkgs }: pkgs.callPackage ./pkg.nix { inherit system; }
