#
# Implementation of the CA functionality declared in the interface.
# We set up Smallstep as a local CA and make it the default CA for
# the NixOS ACME module.
#
{ config, lib, pkgs, ... }:

with lib;

{
  config = let
    # Feature flag.
    enabled = config.odbox.local-ca.enable;

    # Smallstep config and endpoint URL.
    ca-name = "local-ca";
    ca-port = config.odbox.local-ca.port;
    endpoint = "https://localhost:${toString ca-port}/acme/${ca-name}/directory";

    # Snake oil certs and password for our CA.
    root-crt = "${pkgs.odbox.snakeoil-sec}/certs/vault-ca-cert.pem";
    intermediate-crt = root-crt;
    intermediate-key = "${pkgs.odbox.snakeoil-sec}/certs/vault-ca-key.pem";
    intermediate-pwd-file = "${pkgs.odbox.snakeoil-sec}/passwords/admin.txt";

    # Smallstep server config file.
    config-file = import ./smallstep-config.nix {
      inherit pkgs
              root-crt intermediate-crt intermediate-key
              ca-name ca-port;
      svc-home = "/var/lib/${ca-name}";
    };

    # systemd service to run the Smallstep server.
    svc = import ./svc.nix {
      inherit pkgs config-file intermediate-pwd-file;
      svc-usr = ca-name;
      acme-services = [ "acme-${config.odbox.service-stack.domain}.service" ];
    };
  in (mkIf enabled
  {
    # Start the Smallstep service with our config.
    systemd.services."${ca-name}" = svc;

    # Make our Smallstep service the default ACME CA.
    security.acme.defaults.server = endpoint;

    # Add the Smallstep root cert to the lot the OS trusts.
    security.pki.certificateFiles = [ root-crt ];
  });
}
# NOTE
# ----
# 1. NixOS Smallstep service. There's a NixOS service to run the
# Smallstep CA server: `systemd.services.step-ca`. Why not use it?
# B/c it was quicker to write our own than tryna tweak the existing
# one for our needs. In particular, we'd like to have a config file
# where we can easily reference store paths w/o Nix moaning about it
# and we've got to start our service **before** the ACME one tries
# to get a certificate.
# 2. Security. We could make our setup secure by fetching certs and
# passwords from the vault. But at the moment we're only using the
# CA server for testing, so a more complicated setup isn't worth our
# while.
