{
  description = "Flake to build and develop 'odoo.box'.";

  inputs = {
    nixpkgs.url = "github:NixOs/nixpkgs/nixos-23.11";
    nixie = {
      url = "github:c0c0n3/nixie";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixie }:
  let
    inputPkgs = nixpkgs // {
      mkConfig = system: {
        permittedInsecurePackages = [ "qtwebkit-5.212.0-alpha4" ];   # (1)
      };
    };
    build = nixie.lib.flakes.mkOutputSetForCoreSystems inputPkgs;
    pkgs = build (import ./pkgs/mkSysOutput.nix);

    overlay = final: prev: {
      odbox = pkgs.packages.${prev.system} or {};
    };

    modules = {
      nixosModules.imports = [ ./modules ];
    };
  in
    { inherit overlay; } // pkgs // modules;

}
# NOTE
# ----
# 1. qtwebkit. It shouldn't be used but Odoo indirectly depends on it---
# see pkgs/odoo-14/pkg.nix. So we've got to override Nix's decision to
# leave it out of the package set.
#
