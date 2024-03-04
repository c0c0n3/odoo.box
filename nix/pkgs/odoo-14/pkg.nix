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

  wkhtmltopdf-odoo = import ./wkhtmltopdf.nix { inherit wkhtmltopdf; };
                                                               # (1)
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
# 1. wkhtmltopdf. See (1) in `wkhtmltopdf.nix`.
#
# 2. Broken tests. Some tests are broken, so we've got to skip testing.
#
# 3.Stripping. The Odoo 15 package skips stripping, claiming it takes 5+
# minutes and there are no files to strip. So we do the same.
#