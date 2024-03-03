#
# Odoo 14 package. There's no 14 package in Nixpkgs so we've got to build
# our own. We take version 15 as a starting point and then tweak as needed:
# - https://github.com/NixOS/nixpkgs/blob/nixos-23.11/pkgs/applications/finance/odoo/odoo15.nix
#
{
  lib, stdenv, fetchFromGitHub,
  python3, rtlcss, wkhtmltopdf
}:
let
  isLinux = stdenv.isLinux;
  ifLinux = ps: if isLinux then ps else [];

  source = {
    branch = "14.0";
    date = "20240215";
    rev = "6c7f4559386776aaa2cfa8f3df5cd6d2b6c5ed95";
  };

  python = python3;

  wkhtmltopdf-odoo =
  let
    version-tag = "0.12.5";
  in wkhtmltopdf.overrideAttrs (finalAttrs: previousAttrs: {
    version = version-tag;
    src = fetchFromGitHub {
      owner = "wkhtmltopdf";
      repo = "wkhtmltopdf";
      rev = version-tag;
      sha256 = "0i6b6z3f4szspbbi23qr3hv22j9bhmcj7c1jizr7y0ra43mrgws1";
    };
  });                                                          # (1)
in python.pkgs.buildPythonApplication
{
  pname = "odoo14";
  version = "${source.branch}.${source.date}";

  src = fetchFromGitHub {
    owner = "odoo";
    repo = "odoo";
    rev = source.rev;
    sha256 = "sha256-4pUiBNadOWA3RrT2EEK1dLa7YI1KlRx4TQ2Ip5AMMRo=";
  };
  format = "setuptools";

  propagatedBuildInputs = with python.pkgs; [
    babel
    chardet
    decorator
    docutils
    ebaysdk
    freezegun
    gevent
    greenlet
    idna
    jinja2
    libsass
    lxml
    mako
    markupsafe
    num2words
    ofxparse
    passlib
    pillow
    polib
    psutil
    psycopg2
    pydot
    pypdf2
    pyserial
    python-dateutil
    python-ldap
    python-stdnum
    pytz
    pyusb
    qrcode
    reportlab
    requests
    urllib3
    vobject
    werkzeug
    xlrd
    xlsxwriter
    xlwt
    zeep
  ];

  doCheck = false;                                             # (2)

  makeWrapperArgs =
  let
    ps = [ rtlcss ] ++ ifLinux [ wkhtmltopdf-odoo ];           # (1)
  in [
    "--prefix" "PATH" ":" "${lib.makeBinPath ps}"
  ];

  dontStrip = true;                                            # (3)

  meta = with lib; {
    description = "Open Source ERP and CRM";
    homepage = "https://www.odoo.com/";
    license = licenses.lgpl3Only;
  };
}
# NOTE
# ----
# 1. wkhtmltopdf. Odoo 14 requires wkhtmltopdf 0.12.5 but NixOS 23.11 has
# version 0.12.6. So we swap out NixOS's version for ours.
# See:
# - https://github.com/odoo/odoo/wiki/Wkhtmltopdf
# - https://github.com/NixOS/nixpkgs/commit/02bbd55229bbd8128db89aea5d95b97c5af5bd4b
# - https://lazamar.co.uk/nix-versions/?channel=nixpkgs-unstable&package=Wkhtmltopdf
#
# Also notice that neither version can be packaged for Apple silicon because
# the dependency qtwebkit-5.212.0-alpha4 doesn't build there. So we exclude
# wkhtmltopdf when building on MacOS.
#
# 2. Broken tests. Some tests are broken, so we've got to skip testing.
#
# 3.Stripping. The Odoo 15 package skips stripping, claiming it takes 5+
# minutes and there are no files to strip. So we do the same.
#
# 4. qtwebkit. wkhtmltopdf depends on qtwebkit which isn't supported
# any more. If you try building Nix moans loudly about it, but tells
# you what to do if you really want to include qtwebkit. See below the
# output of `nix build .#odoo-14`.
#
# error: Package ‘qtwebkit-5.212.0-alpha4’ in /nix/store/[..] is marked
#        as insecure, refusing to evaluate.
#
# Known issues:
# - QtWebkit upstream is unmaintained and receives no security updates,
#   see https://blogs.gnome.org/mcatanzaro/2022/11/04/stop-using-qtwebkit/
#
# You can install it anyway by allowing this package, using the
# following methods:
#
# a) To temporarily allow all insecure packages, you can use an environment
#     variable for a single invocation of the nix tools:
#
#     $ export NIXPKGS_ALLOW_INSECURE=1
#
#     Note: When using `nix shell`, `nix build`, `nix develop`, etc with a
#           flake, then pass `--impure` in order to allow use of environment
#           variables.
#
# b) for `nixos-rebuild` you can add ‘qtwebkit-5.212.0-alpha4’ to
#     `nixpkgs.config.permittedInsecurePackages` in the configuration.nix,
#     like so:
#
#     {
#         nixpkgs.config.permittedInsecurePackages = [
#         "qtwebkit-5.212.0-alpha4"
#         ];
#     }
#
# c) For `nix-env`, `nix-build`, `nix-shell` or any other Nix command you
#    can add ‘qtwebkit-5.212.0-alpha4’ to `permittedInsecurePackages` in
#     ~/.config/nixpkgs/config.nix, like so:
#
#     {
#         permittedInsecurePackages = [
#         "qtwebkit-5.212.0-alpha4"
#         ];
#     }
