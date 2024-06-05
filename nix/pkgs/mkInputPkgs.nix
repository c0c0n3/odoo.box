#
# Put together the package set to pass in to Nixie package builder
# functions like `nixie.lib.flakes.mkOutputSetForCoreSystems`.
#
{ nixpkgs, poetry2nix, agenix }:
nixpkgs // {
  mkConfig = system: {
    permittedInsecurePackages = [
      "openssl-1.1.1w"
      "qtwebkit-5.212.0-alpha4"
    ];                                                           # (1)
  };
  mkOverlays = system: [
    poetry2nix.overlays.default
    agenix.overlays.default
    (final: prev: {
      mkpasswd = prev.mkpasswd.override {                        # (2)
        stdenv = prev.llvmPackages_14.stdenv;
      };
    })
  ];
}
# NOTE
# ----
# 1. Unsecure/unmaintained libs. They shouldn't be used but Odoo indirectly
# depends on them---see pkgs/odoo-14/pkg.nix. So we've got to override Nix's
# decision to leave them out of the package set.
# 2. mkpasswd. Recent versions (up to `5.5.22`) won't compile with `clang`
# > 14 on Apple Silicon. (Amazingly enough, source compiles just fine on
# Linux.) So we downgrade `clang` to version 14 to be able to build on
# the Mac too. The reason for the source not compiling is that there's
# some uses of implicit function declarations in `mkpasswd.c` (like `strdup`
# and `snprintf`) which recent versions of `clang` treat as errors whereas
# older versions would just issue a warning. We could patch the source
# (not straightforward) or makefile (compiler flags to turn errors back
# into warnings), but the easiest is to just use an older compiler for
# now and wait for upstream to fix this.
#
