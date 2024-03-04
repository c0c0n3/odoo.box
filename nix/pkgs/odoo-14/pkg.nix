#
# Odoo 14 package. There's no 14 package in Nixpkgs so we've got to build
# our own. We take version 15 as a starting point and then tweak as needed:
# - https://github.com/NixOS/nixpkgs/blob/nixos-23.11/pkgs/applications/finance/odoo/odoo15.nix
#
{
  lib, stdenv, fetchzip, poetry2nix, python3,
  rtlcss, wkhtmltopdf
}:
let
  isLinux = stdenv.isLinux;
  ifLinux = ps: if isLinux then ps else [];

  wkhtmltopdf-odoo = import ./wkhtmltopdf.nix { inherit wkhtmltopdf; };
                                                               # (1)
in poetry2nix.mkPoetryApplication rec {
  pname = "odoo14";
  series = "14.0";
  version = "${series}.20231205";

  src = fetchzip {
    url = "https://nightly.odoo.com/${series}/nightly/src/odoo_${version}.tar.gz";
    name = "${pname}-${version}";
    hash = "sha256-ZmDplN3a3Xc1s/ApWaPxP2hADJ46txFByRbsyeD7vt4=";
  };                                                           # (2)
  projectDir = src;
  pyproject = ./pyproject.toml;
  poetrylock = ./poetry.lock;
  python = python3;

  doCheck = false;                                             # (3)
  dontStrip = true;                                            # (4)

  makeWrapperArgs =
  let
    ps = [ rtlcss ] ++ ifLinux [ wkhtmltopdf-odoo ];           # (1)
  in [
    "--prefix" "PATH" ":" "${lib.makeBinPath ps}"
  ];

  meta = with lib; {
    description = "Open Source ERP and CRM";
    homepage = "https://www.odoo.com/";
    license = licenses.lgpl3Only;
  };
}
# NOTE
# ----
# 1. wkhtmltopdf. See (1) in `wkhtmltopdf.nix`.
#
# 2. Source. Why not fetch from GitHub? Because the tarball consolidates
# all the add-ons in the `odoo/addons` dir whereas the repo has them split
# in two dirs: `repo/addons` and `repo/odoo/addons`. If you run the server
# from the repo you'll have to pass the path to the other addons dir since
# some of the modules the code in `repo/odoo` expects are actually in the
# `repo/addons` dir.
#
# 3. Broken tests. Some tests are broken, so we've got to skip testing.
#
# 4.Stripping. The Odoo 15 package skips stripping, claiming it takes 5+
# minutes and there are no files to strip. So we do the same.
#