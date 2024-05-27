Local CA
--------
> Nix module docs.

This module provides a service to issue and renew TLS certificates.

We run our own CA server on localhost with self-signed CA root and
intermediate certificates. Clients interact with the server through
the ACME protocol. The default ACME discovery URL is:
- https://localhost:10443/acme/local-ca/directory

But you can change the port through the [options][iface] this module
provides. Also, this module makes our CA server NixOS's default ACME
server by setting the `security.acme.defaults.server` option to the
above URL. Finally, we add the CA root certificate to the NixOS's
trusted lot through the `security.pki.certificateFiles` option.

At the moment this module's security isn't prod-grade, so you should
only use this module to simulate Let's Encrypt's CA for testing locally
the TLS functionality our [Odoo service stack][svc-stack] provides.


### Example usage

Use the config below to test how our [Odoo service stack][svc-stack]
gets a certificate for Nginx from a CA through the ACME protocol.

```nix
odbox = {
  server.enable = true;
  service-stack.autocerts = true;
  local-ca.enable = true;
}
```

After deploying this config, the `security.acme` module should try
connecting to our local CA to get a certificate for `localhost` or
whatever host you set in `odbox.service-stack.domain`. If you check
the logs, you should see the same flow as [that documented][svc-stack]
for our prod setup with Let's Encrypt.

```bash
$ ssh admin@localhost
$ journalctl -xeu local-ca
$ journalctl -xeu acme-localhost
#                 ^or acme-D where D is the value of odbox.service-stack.domain
```

Then find out what certs the ACME module has configured Nginx with,
e.g.

```bash
$ systemctl status nginx | rg '[-]c .*nginx.conf'
  ...nginx -c /nix/store/fijxxmkfmsv57lb66rq74wawfn0g0g1n-nginx.conf...

$ cat /nix/store/fijxxmkfmsv57lb66rq74wawfn0g0g1n-nginx.conf | rg 'ssl_.*cert.*'
    ssl_certificate /var/lib/acme/localhost/fullchain.pem;
    ssl_certificate_key /var/lib/acme/localhost/key.pem;
    ssl_trusted_certificate /var/lib/acme/localhost/chain.pem;
```

If you decode these certs, you should see an issuer of `vault-ca` as
well as the `local-ca` name in the extension stanza, e.g.

```bash
$ openssl x509 -in /var/lib/acme/localhost/fullchain.pem -noout -text
Certificate:
    Data:
        ...
        Issuer: CN = vault-ca
        Subject: CN = localhost
        ...
        X509v3 extensions:
            1.3.6.1.4.1.37476.9000.64.1:
                0......local-ca..
        ...
```

To see how renewing the certificate works, just reload the systemd
cert service, e.g. `acme-localhost`. Finally, notice that because
the root CA cert is in the NixOS PKI store, you should be able to
use `curl` to interact with Nginx on the same machine without having
to tell `curl` to skip certificate validation (`-k` option):

```bash
$ curl -i https://localhost
HTTP/2 303
server: nginx
location: https://localhost/web
...
```


### Implementation notes

We use the Smallstep CA server to do the heavy-lifting. There's a
NixOS [service][svc] to run it with basic [settings][step-cfg] to
make it work with ACME clients and use our snake oil certs as CA
root and intermediate certs. The NixOS [module][module] implementation
ties everything together.

Read these articles to find out a bit more about Smallstep:
- https://smallstep.com/blog/private-acme-server/
- https://blog.sean-wright.com/self-host-acme-server/
- https://smallstep.com/docs/step-cli/basic-crypto-operations




[iface]: ./interface.nix
[module]: ./module.nix
[step-cfg]: ./smallstep-config.nix
[svc]: ./svc.nix
[svc-stack]: ../service-stack/docs.md
