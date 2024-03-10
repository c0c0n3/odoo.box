#
# Generate the NixOS systemd entry for the Nginx service.
# Tweaked from:
# - https://github.com/NixOS/nixpkgs/blob/nixos-23.11/nixos/modules/services/finance/odoo.nix
#
{ domain }:
{
    enable = true;

    upstreams = {
      odoo.servers = {
        "127.0.0.1:8069" = {};
      };

      odoochat.servers = {
        "127.0.0.1:8072" = {};
      };
    };

    virtualHosts."${domain}" = {
      extraConfig = ''
        proxy_read_timeout 720s;
        proxy_connect_timeout 720s;
        proxy_send_timeout 720s;

        proxy_set_header X-Forwarded-Host $host;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Real-IP $remote_addr;
      '';

      locations = {
        "/longpolling" = {
          proxyPass = "http://odoochat";
        };

        "/" = {
          proxyPass = "http://odoo";
          extraConfig = ''
            proxy_redirect off;
          '';
        };
      };
  };
}