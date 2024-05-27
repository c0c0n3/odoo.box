#
# See `docs.md` for module documentation.
#
{ config, lib, pkgs, ... }:

with lib;
with types;

{

  options = {
    odbox.local-ca.enable = mkOption {
      type = bool;
      default = false;
      description = ''
        Enable it to start a local CA server that lets ACME clients
        acquire and renew TLS certificates. The ACME discovery URL
        format is `https://localhost:<port>/acme/local-ca/directory`
        where `port` is the value of the `odbox.local-ca.port` option,
        e.g. `https://localhost:10443/acme/local-ca/directory`.
      '';
    };
    odbox.local-ca.port = mkOption {
      type = port;
      default = 10443;
      description = ''
        The port the certificate authority server should listen on.
      '';
    };
  };

}
