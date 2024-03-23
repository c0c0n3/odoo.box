#
# Function to generate the NixOS configurations for the Flake output.
#
{
  # `lib.nixosSystem` in the selected Nixpkgs.
  nixosSystem,
  # The Flake itself.
  odbox
}:
let
  mkNode = system: config: nixosSystem {
    inherit system;
    modules = [
      ({ config, pkgs, ... }: { nixpkgs.overlays = [ odbox.overlay ]; })
      odbox.nixosModules
      config
    ];
  };
in {
  nixosConfigurations = {
    devm = mkNode "aarch64-linux" ./devm-aarch64/configuration.nix;
  };
}
