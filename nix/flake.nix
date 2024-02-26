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
    build = nixie.lib.flakes.mkOutputSetForCoreSystems nixpkgs;
    pkgs = build (import ./pkgs/mkSysOutput.nix);

    overlay = final: prev:
    {
      odbox = pkgs.packages.${prev.system} or {};
    };

    modules = {
      nixosModules.imports = [ ./modules ];
    };
  in
    { inherit overlay; } // pkgs // modules;

}
