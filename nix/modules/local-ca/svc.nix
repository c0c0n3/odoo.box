#
# Generate the systemd service unit for the Smallstep server.
#
{
  # Nix packages.
  pkgs,
  # Service user.
  svc-usr,
  # Server config file.
  config-file,
  # Password file for the intermediate certificate private key.
  intermediate-pwd-file,
  # List of service names the ACME module sets up for each cert you
  # asked ACME to acquire from the default CA configured in the ACME
  # module. Each service name has the format `acme-CN.service` where
  # CN is the domain name the cert is for---e.g. `acme-localhost.service`,
  # `acme-some.other.host.service`
  acme-services
}:
{
  wantedBy = [ "multi-user.target" ];
  before = acme-services;
  requiredBy = acme-services;
  restartTriggers = [ config-file ];

  path = [ pkgs.step-ca ];

  script = ''
    step-ca ${config-file} --password-file ${intermediate-pwd-file}
  '';
  postStart = ''
    sleep 2
  '';                                                          # (1)

  serviceConfig = {
    Type = "exec";                                             # (1)
    DynamicUser = true;
    User = svc-usr;
    StateDirectory = svc-usr;
  };
}
# NOTE
# ----
# 1. Waiting for CA server. We'd like to start the ACME services only
# after the CA server is accepting connections---otherwise the Lego
# client will fail to connect and won't be able to get a cert from
# the CA server. It doesn't look like `step-ca` supports any kind of
# notification we could leverage w/ the systemd notify facility. So
# the best we can do is set the service type to `exec` and wait a
# couple of secs after systemd has started the process, which, b/c
# of the `exec` type, will be after systemd called `fork` + `execve`
# and the latter returned successfully.
