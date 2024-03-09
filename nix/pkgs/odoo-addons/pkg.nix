#
# Martel's Odoo addons collection.
# This package provides the source of each addon Martel uses in prod.
# Sources are conveniently laid out in the package output dir so you
# can simply add the output dir to your Odoo server's addons path to
# make them available to the server.
#
{
    stdenv, fetchFromGitHub
}:
let
  vendor = ../../../vendor/addons;                             # (1)
  hr-timesheet-overtime = fetchFromGitHub {
    owner = "martel-innovate";
    repo = "hr_timesheet_overtime";
    rev = "b8f82871acf13f93ebe1a3d5b294832dba71de50";          # (2)
    sha256 = "sha256-EI4KIiHTywUqW3HYp+nn43qaqpBxQK91WFkHGgym16A=";
  };
  timesheets-by-employee = fetchFromGitHub {
    owner = "martel-innovate";
    repo = "timesheets_by_employee";
    rev = "934c519d63c5fad4c19055e930cad4e21e6940fc";          # (2)
    sha256 = "sha256-GuRROvxTx2qxtlI2N9dA0R6pxmg17O/kN6xbDpnWl7U=";
  };
in stdenv.mkDerivation rec {
    pname = "odoo-addons";
    version = "1.0.0-odoo-14.0";

    src = vendor;
    src-hr-timesheet-overtime = hr-timesheet-overtime;
    src-timesheets-by-employee = timesheets-by-employee;

    installPhase = ''
      mkdir -p $out/hr_timesheet_overtime
      cp -rv ${src-hr-timesheet-overtime}/. $out/hr_timesheet_overtime

      mkdir -p $out/timesheets_by_employee
      cp -rv ${src-timesheets-by-employee}/. $out/timesheets_by_employee

      cp -rv $src/* $out
    '';
}
# NOTE
# ----
# 1. Vendor addons. At the moment the sources for the various vendor
# addons installed in Martel's prod Odoo are in this repo after being
# copied over from prod. This is not the way to go, but rather a stop
# gap solution. See #2.
# 2. Release tags. Ideally we'd use release tags instead of revs. But
# at the moment hr-timesheet-overtime and timesheets-by-employee don't
# have a release process in place.
#