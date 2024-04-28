#
# See `docs.md` for package documentation.
#
{ pkgs, db-init, vaultgen }:
let
  admin = import ./admin.nix { inherit pkgs; };
  dev = import ./dev.nix { inherit pkgs db-init vaultgen; };
in rec {

  # Make a shell env with all the given programs.
  # Notice we also add the program paths to the derivation so you can
  # reference them later if needed. E.g. in NixOS
  #
  #    environment.systemPackages = pkgs.your-derivation.paths;
  #
  # See also NOTE (1) below.
  mkShell = name: paths: pkgs.buildEnv {
    inherit name paths;
  } // { inherit paths; };

  linux-admin-shell = mkShell "linux-admin-shell" admin.all;
  dev-shell = mkShell "dev-shell" dev.all;
  full-shell = mkShell "full-shell" (dev.all ++ admin.all);

}
# NOTE
# ----
# 1. `mkShell`. We roll out our own function to create a derivation to make
# programs available in the PATH when instantiated through `nix shell`. This
# is because the built-in `mkShell` only works with `nix develop`. See:
# - https://github.com/c0c0n3/nixie/wiki/Fiddling-about-with-Nix-dev-envs
#