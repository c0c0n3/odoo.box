Service Stack
-------------
> Nix module docs.

Service stack to run Odoo.


### Overview

This [module][iface] configures a fully-fledged service stack to run
Odoo on a single machine:
- Odoo multi-processing server, including LiveChat gevent process
  and configurable user session timeout.
- Sane, automatically generated Odoo [config][cfg].
- Odoo [addons][addons].
- [Systemd service][svc] to run Odoo, including daemon user and
  secure handling of Odoo admin password.
- [Systemd service][pgadmin] to run PgAdmin, including daemon user,
  zero-config DB init with automatic connection to Postgres from
  the Web UI, and secure handling of PgAdmin Web UI admin password.
- Non-network Postgres DB [backend][mod] (both Odoo and PgAdmin
  connect to Unix sockets) with [automatic creation][init] of Odoo
  & PgAdmin DBs and roles as well as strict security policies.
- Nginx TLS reverse [proxy][proxy] to safely expose Odoo and PgAdmin
  to the internet.
- Automatic request, installation and renewal of TLS certs using
  Let's Encrypt as a CA.

Also, this module makes `psql` and the Odoo CLI available system-wide
to help with maintenance tasks.

From DBs to services to security, we wire everything together to
make the whole service stack work out of the box without any extra
manual config. As for security, we stick to Least Privilege and Zero
Trust principles.

Notice this module comes with a bootstrap option to migrate an Odoo
DB and file store from another Odoo server. In bootstrap mode you
get all the goodies in the the Odoo service stack except for a running
Odoo server. The Odoo user and service will be there as well as the
`odoo` binary, but the server won't run. This is useful if you want
to bootstrap your Odoo DB and file store yourself—think migrating
data from another Odoo server. In fact, it's not a good idea to have
Odoo kick around while you bootstrap its data as experience has shown.


### Basic usage

Bootstrap mode:

```nix
odbox.service-stack = {
  enable = true;
  bootstrap-mode = true;

  # optionally
  pgadmin-enable = true;
};
```

Normal prod mode:

```nix
odbox.service-stack = {
  enable = true;
  odoo-db-name = "odoo_martel_14";
  odoo-cpus = 4;

  # optionally
  pgadmin-enable = true;
};
```


### Session timeout

You can configure a Odoo user session timeout. This is a positive
number of minutes `M` that determines how long a logged-in user is
allowed to be inactive before they're automatically logged out. If
the user's browser hasn't sent a request to the Odoo server in `M`
minutes, the user session gets deleted and the user is forced to
log in again.

The default session timeout is 5 minutes. To change it, use the
`odoo-session-timeout` option as in the example below where we set
a timeout of 14 days. (This is just an example to show you can use
a Nix expression to compute the value; in real life probably you
wouldn't want a 14-day timeout, unless security isn't a concern.)

```nix
odbox.service-stack = {
  odoo-session-timeout = 14 * 24 * 60;
  # ...other options
};
```

We should mention Odoo has built-in support for session clean-up.
So why roll out our own solution? First off, Odoo doesn't let you
configure a session timeout, so you're stuck with the hardcoded
value of one week—unless you install additional plugins. Second,
in an ideal world, Odoo should clean up after itself, but that
doesn't always happen and overtime you could pile up truck loads
of stale session files which would slow down directory access and
in turn slow down Odoo itself. More details over here:
- https://github.com/c0c0n3/odoo.box/pull/25#issuecomment-2152662861


### TLS certificates

For a prod deployment, you should have a valid TLS cert Ngnix can
use. You can certainly buy one and import it into Odoo Box—see the
[Vault module][vault] for the details. But another option is to turn
on the auto-certs feature this module provides. With auto-certs on,
Odoo Box automatically acquires and renews a TLS certificate from
Let's Encrypt. The certs is tied to the fully-qualified domain name
of the machine Odoo Box runs on. So you need a proper DNS record for
this to work and you also have to specify an email address Let's
Encrypt can use to create an account and link it to the certificate
it issues. The auto-certs implementation uses `odbox.login.admin-email`
as an email for Let's Encrypt. Here's a complete example.

```nix
odbox = {
  login.admin-email = "andrea.falconi@martel-innovate.com";
  service-stack = {
    enable = true;
    autocerts = true;
    domain = "test-odoo.martel-innovate.com";

    # ...other service stack settings
  };
};
```

#### A look under the bonnet
We configure the NixOS Nginx module to use Let's Encrypt. In turn,
that module delegates most of the work to the ACME module. Finally,
the ACME module uses the `lego` client to carry out ACME procedures
to acquire and renew certs. These procedures get triggered by a systemd
service which, after the first run to acquire the certificate, runs
once a day to check if the certificate should be renewed. The unit's
name has the format `acme-<domain>.service`.

Here's what happened when we went live with the above config for
`test-odoo.martel-innovate.com`.

```bash
$ journalctl -xeu acme-test-odoo.martel-innovate.com.service
```

```
...
...: + set -euo pipefail
...: + mkdir -p /var/lib/acme/acme-challenge/.well-known/acme-challenge
...: + chgrp nginx /var/lib/acme/acme-challenge/.well-known/acme-challenge
...: + echo e4968fd060f5714e1e87
...: + cmp -s domainhash.txt certificates/domainhash.txt
...: + lego --accept-tos --path . -d test-odoo.martel-innovate.com --email andrea.falconi@martel-innovate.com --key-type ec256 --http --http.webroot /var/lib/acme/acme-challenge run
...: 2024/05/03 16:56:28 No key found for account andrea.falconi@martel-innovate.com. Generating a P256 key.
...: 2024/05/03 16:56:28 Saved key to accounts/acme-v02.api.letsencrypt.org/andrea.falconi@martel-innovate.com/keys/andrea.falconi@martel-innovate.com.key
...: 2024/05/03 16:56:28 [INFO] acme: Registering account for andrea.falconi@martel-innovate.com
...: !!!! HEADS UP !!!!
...: Your account credentials have been saved in your Let's Encrypt
...: configuration directory at "accounts".
...: You should make a secure backup of this folder now. This
...: configuration directory will also contain certificates and
...: private keys obtained from Let's Encrypt so making regular
...: backups of this folder is ideal.
...: 2024/05/03 16:56:28 [INFO] [test-odoo.martel-innovate.com] acme: Obtaining bundled SAN certificate
...: 2024/05/03 16:56:29 [INFO] [test-odoo.martel-innovate.com] AuthURL: https://acme-v02.api.letsencrypt.org/acme/authz-v3/346212285947
...: 2024/05/03 16:56:29 [INFO] [test-odoo.martel-innovate.com] acme: Could not find solver for: tls-alpn-01
...: 2024/05/03 16:56:29 [INFO] [test-odoo.martel-innovate.com] acme: use http-01 solver
...: 2024/05/03 16:56:29 [INFO] [test-odoo.martel-innovate.com] acme: Trying to solve HTTP-01
...: 2024/05/03 16:56:33 [INFO] [test-odoo.martel-innovate.com] The server validated our request
...: 2024/05/03 16:56:33 [INFO] [test-odoo.martel-innovate.com] acme: Validations succeeded; requesting certificates
...: 2024/05/03 16:56:34 [INFO] [test-odoo.martel-innovate.com] Server responded with a certificate.
...: + mv domainhash.txt certificates/
...: + chown acme:nginx certificates/domainhash.txt certificates/test-odoo.martel-innovate.com.crt certificates/test-odoo.martel-innovate.com.issuer.crt certificates/test-odoo.martel-innovate.com.json certificates/test-odoo.martel-innovate.com.key
...: + cmp -s certificates/test-odoo.martel-innovate.com.crt out/fullchain.pem
...: + touch out/renewed
...: + echo Installing new certificate
...: Installing new certificate
...: + cp -vp certificates/test-odoo.martel-innovate.com.crt out/fullchain.pem
...: 'certificates/test-odoo.martel-innovate.com.crt' -> 'out/fullchain.pem'
...: + cp -vp certificates/test-odoo.martel-innovate.com.key out/key.pem
...: 'certificates/test-odoo.martel-innovate.com.key' -> 'out/key.pem'
...: + cp -vp certificates/test-odoo.martel-innovate.com.issuer.crt out/chain.pem
...: 'certificates/test-odoo.martel-innovate.com.issuer.crt' -> 'out/chain.pem'
...: + ln -sf fullchain.pem out/cert.pem
...: + cat out/key.pem out/fullchain.pem
...: + chmod 640 out/cert.pem out/chain.pem out/fullchain.pem out/full.pem out/key.pem out/renewed
...
```

All the account and cert files end up in `/var/lib/acme`. This is
what that directory looked like just after the cert acquisition ran:

```
/var/lib/acme
├── .lego
│  ├── accounts
│  │  └── 8569a7ce81f6811b52c7
│  │     └── acme-v02.api.letsencrypt.org
│  │        └── andrea.falconi@martel-innovate.com
│  │           ├── account.json
│  │           └── keys
│  │              └── andrea.falconi@martel-innovate.com.key
│  └── test-odoo.martel-innovate.com
│     └── 549839e4ae8616de7ad5
│        ├── domainhash.txt
│        ├── test-odoo.martel-innovate.com.crt
│        ├── test-odoo.martel-innovate.com.issuer.crt
│        ├── test-odoo.martel-innovate.com.json
│        └── test-odoo.martel-innovate.com.key
├── .minica
│  ├── cert.pem
│  └── key.pem
├── acme-challenge
│  └── .well-known
│     └── acme-challenge
└── test-odoo.martel-innovate.com
   ├── cert.pem -> fullchain.pem
   ├── chain.pem
   ├── full.pem
   ├── fullchain.pem
   └── key.pem
```

Notice the `lego` client suggests to make backups of the account and
certificate directories. But since we're running NixOS and everything
is reproducible, not making a backup isn't too much of an issue. If
we ever lose the certificate and account, the NixOS module will get
new ones anyway. Also, it looks like starting all over from scratch
isn't too much of a big deal as the Let's Encrypt guys point out
- https://community.letsencrypt.org/t/what-is-an-account/209782/13

For the sake of completeness, here's another service log extract
which shows what happens with the daily renewal check.

```
...
...: ++ find accounts -name andrea.falconi@martel-innovate.com.key
...: + '[' -e certificates/test-odoo.martel-innovate.com.key -a -e certificates/test-odoo.martel-innovate.com.crt -a -n accounts/acme-v02.api.letsencrypt.org/andrea.falconi@martel-innovate.com/keys/andrea.falconi@martel-innovate.com.key ']'
...: + lego --accept-tos --path . -d test-odoo.martel-innovate.com --email andrea.falconi@martel-innovate.com --key-type ec256 --http --http.webroot /var/lib/acme/acme-challenge renew --no-random-sleep --days 30
...: 2024/05/03 17:24:13 [test-odoo.martel-innovate.com] The certificate expires in 89 days, the number of days defined to perform the renewal is 30: no renewal.
...
```




[addons]: ../../pkgs/odoo-addons/docs.md
[cfg]: ./odoo-config.nix
[iface]: ./interface.nix
[init]: ./db-init.nix
[mod]: ./module.nix
[pgadmin]: ./pgadmin.nix
[proxy]: ./nginx.nix
[svc]: ./odoo-svc.nix
[vault]: ../vault/docs.md
