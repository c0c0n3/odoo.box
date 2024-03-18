#
# Generate the NixOS systemd entry for the Nginx service.
# We start off with the Nginx SSL example config in the Odoo 14 docs
# and then bolt on recommended Nginx settings.
# See:
# - https://www.odoo.com/documentation/14.0/administration/install/deploy.html#https
#
{ sslCertificate, sslCertificateKey, domain }:
{
    enable = true;

    # Configure basic optimisation params.
    recommendedOptimisation = true;

    # Turn on recommended proxy settings.
    # These two settings below configure all the headers required for
    # Odoo proxy mode as well as all the proxy related timeouts as in
    # in the SSL config example found in the Odoo 14 docs.
    recommendedProxySettings = true;
    proxyTimeout = "720s";

    # Ditto for TLS settings.
    # Notice this option configures all the Nginx SSL settings in the
    # Odoo example Ngnix config except for certs.
    recommendedTlsSettings = true;

    # Ditto for Gzip settings.
    # Notice the Nix config list alot of MIME types to compress. This
    # list contains all the MIME types in the Odoo config example except
    # for 'text/scss'. But 'text/scss' ain't a MIME type AFAIK. So we
    # leave that one out.
    recommendedGzipSettings = true;

    upstreams = {
      odoo.servers = {
        "127.0.0.1:8069" = {};
      };
      odoochat.servers = {
        "127.0.0.1:8072" = {};
      };
    };

    virtualHosts."${domain}" = {
      inherit sslCertificate sslCertificateKey;

      # Our Odoo stack is supposed to run on a dedicated box. So we
      # only need this one Nginx server which is why we make it the
      # the default server.
      default = true;

      # Redirect (301) plain HTTP traffic on port 80 to HTTPS on port 443.
      forceSSL = true;

      locations = {
        # Forward long-polling requests to the Odoo gevent server.
        "/longpolling" = {
          proxyPass = "http://odoochat";
        };
        # Forward requests to the Odoo backend server.
        "/" = {
          proxyPass = "http://odoo";
          extraConfig = ''
            proxy_redirect off;
          '';
        };
      };
  };
}