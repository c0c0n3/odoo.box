#
# See `docs.md` for module documentation.
#
{ config, lib, pkgs, ... }:

with lib;
with types;

{
  options = {
    odbox.vault.root-pwd-file = mkOption {
      type = nullOr path;
      default = null;
      description = ''
        File containing the root user's password hashed in a way `chpasswd`
        can handle.
      '';
    };
    odbox.vault.root-ssh-file = mkOption {
      type = nullOr path;
      default = null;
      description = ''
        File containing the root user's SSH public key. If specified the
        key gets added to the authorised SSH keys so the user can log in
        through SSH with their private key instead of using a password.
      '';
    };
    odbox.vault.admin-pwd-file = mkOption {
      type = nullOr path;
      default = null;
      description = ''
        File containing the admin user's password hashed in a way `chpasswd`
        can handle.
      '';
    };
    odbox.vault.admin-ssh-file = mkOption {
      type = nullOr path;
      default = null;
      description = ''
        File containing the admin user's SSH public key. If specified the
        key gets added to the authorised SSH keys so the user can log in
        through SSH with their private key instead of using a password.
      '';
    };
    odbox.vault.odoo-admin-pwd-file = mkOption {
      type = path;
      default = abort "missing Odoo admin password!";
      description = ''
        File containing the Odoo admin user's clear-text password.
      '';
    };
    odbox.vault.pgadmin-admin-pwd-file = mkOption {
      type = nullOr path;
      default = null;
      description = ''
        File containing the PgAdmin Web UI admin user's clear-text password.
      '';
    };
    odbox.vault.nginx-cert = mkOption {
      type = nullOr path;
      default = null;
      description = "Path to the Nginx's TLS certificate.";
    };
    odbox.vault.nginx-cert-key = mkOption {
      type = nullOr path;
      default = null;
      description = "Path to the Nginx's TLS certificate key.";
    };
  };

  config.assertions = mkOverride 10000                         # (1)
  [
    { assertion = config.odbox.vault.root-pwd-file == null &&
                  config.odbox.vault.root-ssh-file == null;
      message = ''
        The NixOS root user has no login credentials. You must set
        either a password or an SSH public key, or set both.
      '';
    }
    { assertion = config.odbox.vault.admin-pwd-file == null &&
                  config.odbox.vault.admin-ssh-file == null;
      message = ''
        The NixOS admin user has no login credentials. You must set
        either a password or an SSH public key, or set both.
      '';
    }
    { assertion = config.odbox.service-stack.pgadmin-enable &&
                  config.odbox.vault.pgadmin-admin-pwd-file == null;
      message = ''
        The PgAdmin Web UI admin user has no password. You must set
        a password if you enable PgAdmin.
      '';
    }
    { assertion = !config.odbox.service-stack.autocerts &&
                  config.odbox.vault.nginx-cert == null;
      message = ''
        Missing Nginx's TLS certificate.
      '';
    }
    { assertion = !config.odbox.service-stack.autocerts &&
                  config.odbox.vault.nginx-cert-key == null;
      message = ''
        Missing Nginx's TLS certificate key.
      '';
    }
  ];
}
# NOTE
# ----
# 1. Assertions. Basic sanity checks to avoid users shooting themselves
# in the foot. Notice we've got to use a ridiculous override to stop
# these assertions being evaluated too early when the options haven't
# been set yet by the machine config---see e.g. devm config. Ideally
# we should use `mkAfter` (or even `mkOrder 10000`) instead of that
# `mkOverride 10000` which actually discards any assertion with a
# priority higher than 10000---I doubt there's any though. Except
# for some reason `mkAfter` or `mkOrder` don't work in our case!
#
# 2. Redundant cred checks. For each regular user, NixOS actually
# already checks that at least of password or SSH key is set. Even
# though our assertions are redundant, we keep them there for the
# sake of better documentation.
#
