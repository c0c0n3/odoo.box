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
    ec2-aarch64 = mkNode "aarch64-linux" ./ec2-aarch64/configuration.nix;
    ec2-aarch64-boot = mkNode "aarch64-linux" ./ec2-aarch64/config-boot.nix;
    ec2-x86_64 = mkNode "x86_64-linux" ./ec2-x86_64/configuration.nix;
    ec2-x86_64-boot = mkNode "x86_64-linux" ./ec2-x86_64/config-boot.nix;
    devm = mkNode "aarch64-linux" ./devm-aarch64/configuration.nix;
    devm-boot = mkNode "aarch64-linux" ./devm-aarch64/config-boot.nix;
  };
}
