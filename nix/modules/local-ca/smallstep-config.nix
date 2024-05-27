#
# Generate the Smallstep server config file.
# See:
# - https://smallstep.com/docs/step-ca/configuration
#
{
  # Nix packages.
  pkgs,
  # Root and intermediate CA cert files.
  root-crt, intermediate-crt, intermediate-key,
  # Service params: CA name, server port and service home dir.
  ca-name, ca-port, svc-home
}:
let
  config = (pkgs.formats.json { }).generate "ca.json";
in config {
  root = root-crt;
  crt = intermediate-crt;
  key = intermediate-key;
  address = ":${toString ca-port}";
  db = {
    type = "badgerv2";
    dataSource = "${svc-home}/db";
  };
  authority = {
    provisioners = [
      {
        type = "ACME";
        name = ca-name;
      }
    ];
  };
}