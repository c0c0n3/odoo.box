{
  inputs = {
    # odbox.url = "github:c0c0n3/odoo.box?dir=nix";
    # ...or use the url below to deploy straight from your clone.
    odbox.url = "../../";
    nixos.follows = "odbox/nixpkgs";
  };

  outputs = { self, nixos, odbox }: {
    nixosConfigurations.devm = nixos.lib.nixosSystem {
      system = "aarch64-linux";
      modules = [
        ({ config, pkgs, ... }: { nixpkgs.overlays = [ odbox.overlay ]; })
        odbox.nixosModules
        ./configuration.nix
      ];
    };
  };
}
