{
  description = "Flake to build and develop 'odoo.box'.";

  inputs = {
    nixpkgs.url = "github:NixOs/nixpkgs/nixos-23.11";
    nixie = {
      url = "github:c0c0n3/nixie";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    poetry2nix = {
      url = "github:nix-community/poetry2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixie, poetry2nix, agenix }:
  let
    inputPkgs = import ./pkgs/mkInputPkgs.nix {
      inherit nixpkgs poetry2nix agenix;
    };
    build = nixie.lib.flakes.mkOutputSetForCoreSystems inputPkgs;
    pkgs = build (import ./pkgs/mkSysOutput.nix);

    overlay = final: prev: {
      odbox = pkgs.packages.${prev.system} or {};
    };

    modules = {
      nixosModules.imports = [
        agenix.nixosModules.default
        ./modules
      ];
    };

    nodes = import ./nodes {
      nixosSystem = nixpkgs.lib.nixosSystem;
      odbox = self;
    };
  in
    { inherit overlay; } // pkgs // modules // nodes;

}
