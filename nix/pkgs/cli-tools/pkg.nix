#
# CLI tools to manage a Linux "odoo.box" machine as well as tools to
# develop "odoo.box". There's two shells you can use:
#
# - linux-admin-shell: widely-used Linux sys-admin tools.
# - dev-shell: dev tools.
#
# The dev shell is the default package, so `nix shell` will drop you
# into a shell with the tools you need to develop "odoo.box". The admin
# shell contains all the sys admin tools we install on "odoo.box".
#
# If you're on MacOS and would also like to get (most of) the admin
# tools with your dev shell, just run
#
# $ nix shell .#dev-shell .#linux-admin-shell
#
# That gets you the whole shebang.
#
{ pkgs }:
let
  admin = import ./admin.nix { inherit pkgs; };
  dev = import ./dev.nix { inherit pkgs; };
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

}
# NOTE
# ----
# 1. `mkShell`. We roll out our own function to create a derivation to make
# programs available in the PATH when instantiated through `nix shell`. This
# is because the built-in `mkShell` only works with `nix develop`. See:
# - https://github.com/c0c0n3/nixie/wiki/Fiddling-about-with-Nix-dev-envs
#