Vaultgen
--------
> Nix package docs.

This package provides the `vaultgen` command to generate, import and
manage `odbox` vault files. That is, the files (secrets) that you'd
typically use with the `odbox.vault` [module][module].


### Functionality

To use the `odbox` vault, you need Age-encrypted certs and password
files as well as the Age identity to decrypt them. `vaultgen` lets
you generate or import these files and easily update them whenever
needed. Plus, `vaultgen` generates a convenience SSH identity, a CA
authority and a `.gitignore` file to avoid committing sensitive data
to the repo. Let's have a look at each of these files in turn.

#### Age identity
First off, to encrypt files `vaultgen` needs an Age pub key. This
key is paired to an Age identity that you provide or one `vaultgen`
generates for you. Either way, `vaultgen` extracts the pub key from
the Age identity file.

#### Passwords
There's a set of four password files for each built-in user: NixOS
root user, NixOS admin user, Odoo Web UI admin, and PgAdmin Web UI
admin. Each set incudes the following files:
- Clear text. A file containing the password in clear text. This
  is either a password you specify or (a strong, memorable) one
  `vaultgen` automatically generates if you don't specify one.
- Age. A file containing the password encrypted using the Age
  key.
- SHA512. A file containing a SHA512 hash of the password that
  `chpasswd` can handle.
- SHA512 Age. A file containing the SHA512 hash encrypted using
  the Age key.
- Yescrypt. A file containing a Yescrypt hash of the password
  `chpasswd` can handle.
- Yescrypt Age. A file containing the Yescrypt hash encrypted
  using the Age key.

#### Certificates
There's also a set of four files for each TLS cert you'd like to
stash away in the vault:
- Pub cert file. Contains the public part of the certificate.
- Age pub cert file. Contains the Age-encrypted pub certificate.
  (Technically this one doesn't need to be encrypted, but we do
  it anyway so you can easily use this file too with the vault
  module.)
- Cert key file. Contains the certificate's private key.
- Age key file. Age-encrypted certificate's private key.

Typically you'd use TLS certs with Nginx but obviously `vaultgen`
doesn't care what you do with them. What `vaultgen` does for you,
it automatically generates a basic self-signed, 100-year valid, RSA
TLS certificate in PEM format for a CA and then uses it to sign any
other cert it generates. By default, `vaultgen` only generates a
certificate for the `localhost` CN, but you can change the CN to
something else or generate certs for multiple CNs—see below. Read
the articles below for a quick intro to CAs, certs and how to add
a CA to your browser to make it validate the certificates `vaultgen`
generates:
- https://gist.github.com/soarez/9688998
- https://hackernoon.com/how-to-get-sslhttps-for-localhost-i11s3342

Keep in mind `vaultgen` can also import your own prod pub cert and
private key into the `vault/certs` directory. On importing, `vaultgen`
encrypts the private key and writes it to a corresponding `.age` file.

#### SSH identity
`vaultgen` also generates a convenience SSH identity. This is an
ED25519 key pair output in `vault/ssh`. You can use the pub key to
configure SSH remote access with the [Login module][login]—or use
it in any other place where you need an SSH identity if you don't
have one already.

#### gitignore
Finally notice `vaultgen` also generates a safety-net `.gitignore`
file. The file tells `git` to ignore any file `vaultgen` may output
except for Age-encrypted and public key files.

#### Vault directory contents
A typical `vaultgen` run to generate a vault from a clean slate would
produce the following dirs and files:

```
 vault
 ├── .gitignore                  # make git track only encrypted or pub files
 ├── age.key                     # Age identity
 ├── certs
 │  ├── localhost-cert.pem       # generated localhost pub cert signed w/ vault-ca
 │  ├── localhost-cert.pem.age   # Age-encrypted localhost pub cert
 │  ├── localhost-key.pem        # generated localhost cert key
 │  ├── localhost-key.pem.age    # Age-encrypted localhost cert key
 │  ├── vault-ca-cert.pem        # self-signed CA pub cert
 │  ├── vault-ca-cert.pem.age    # Age-encrypted CA pub cert
 │  ├── vault-ca-key.pem         # generated CA cert key
 │  └── vault-ca-key.pem.age     # Age-encrypted CA cert key
 ├── passwords
 │  ├── admin.txt                # clear-text admin pwd (generated or entered)
 │  ├── admin.txt.age            #   Age-encrypted clear-text pwd
 │  ├── admin.sha512             #   SHA512-hashed pwd `chpasswd` can handle
 │  ├── admin.sha512.age         #   corresponding Age-encrypted hashed pwd
 │  ├── admin.yesc               #   Yescrypt-hashed pwd `chpasswd` can handle
 │  ├── admin.yesc.age           #   corresponding Age-encrypted hashed pwd
 │  ├── odoo-admin.txt           # clear-text Odoo admin pwd (generated or entered)
 │  ├── odoo-admin.txt.age       #   Age-encrypted clear-text pwd
 │  ├── odoo-admin.sha512        #   SHA512-hashed pwd `chpasswd` can handle
 │  ├── odoo-admin.sha512.age    #   corresponding Age-encrypted hashed pwd
 │  ├── odoo-admin.yesc          #   Yescrypt-hashed pwd `chpasswd` can handle
 │  ├── odoo-admin.yesc.age      #   corresponding Age-encrypted hashed pwd
 │  ├── pgadmin-admin.txt        # clear-text PgAdmin UI admin pwd (generated or entered)
 │  ├── pgadmin-admin.txt.age    #   Age-encrypted clear-text pwd
 │  ├── pgadmin-admin.sha512     #   SHA512-hashed pwd `chpasswd` can handle
 │  ├── pgadmin-admin.sha512.age #   corresponding Age-encrypted hashed pwd
 │  ├── pgadmin-admin.yesc       #   Yescrypt-hashed pwd `chpasswd` can handle
 │  ├── pgadmin-admin.yesc.age   #   corresponding Age-encrypted hashed pwd
 │  ├── root.txt                 # clear-text root pwd (generated or entered)
 │  ├── root.txt.age             #   Age-encrypted clear-text pwd
 │  ├── root.sha512              #   hashed pwd that `chpasswd` can handle
 │  ├── root.sha512.age          #   Age-encrypted hashed pwd
 │  ├── root.yesc                #   Yescrypt-hashed pwd `chpasswd` can handle
 │  └── root.yesc.age            #   corresponding Age-encrypted hashed pwd
 └── ssh
    ├── id_ed25519               # generated ED25519 identity
    └── id_ed25519.pub           # corresponding public key
```


### Basic usage

Called without any argument, `vaultgen` prompts you for cleartext
passwords and then generates all the files listed in the vault dir
contents section. If the `vault` directory already exists, `vaultgen`
only generates any files that are missing from that list or are out
of date. So if you'd like to generate everything from scratch, run

```bash
$ rm -rf vault
$ vaultgen
```

Notice that if you just hit return at a password prompt, `vaultgen`
will generate a strong, memorable password for you. Ideally we'd
always use strong passwords, so if you're not sure about how strong
a password you chose could be, rather let `vaultgen` choose one for
you.

As mentioned earlier, `vaultgen` only generates what's missing or
out of date. In general, if you called `vaultgen` many times in a
row with the same args, only the first call would have an effect,
all subsequent calls would do nothing. So you can selectively update
some of the passwords and have `vaultgen` re-encrypt them with the
existing Age identity. For example, to change the NixOS admin user's
password but nothing else, run

```bash
$ rm -rf vault/passwords/admin.*
$ vaultgen
```

`vaultgen` will only prompt you for the admin password, regenerate
the corresponding hash files and then, in turn, the encrypted files
using the existing `vault/age.key`. Similarly, you could delete the
CA to make `vaultgen` generate a new one and then re-sign the local
host cert with the new CA:

```bash
$ rm -rf vault/certs/vault-ca*
$ vaultgen
```

This will also work with any other certs `vaultgen` generates—see
the *Advanced usage* section. Likewise, if you zap the SSH identity,
`vaultgen` will generate a new one—again without touching any of the
other files like passwords and certs that have already been generated:

```bash
$ rm -rf vault/ssh/id_ed25519*
$ vaultgen
```

Another thing you can do with `vaultgen` is import a TLS prod cert
so you can later link it to the `odbox.vault` [module][module] which
will then make Nginx use it. To import a public certificate and its
corresponding key, use the `import` subcommand, passing the path to
the pub cert file as first argument and the path to the key file as
second arg as in the example below. `vaultgen` will copy the two files
over to the `vault/certs` dir and also encrypt them with `vault/age.key`.

```bash
$ vaultgen import stash/prod-cert.pem stash/prod-key.pem
$ eza vault/certs/prod*
vault/certs/prod-cert.pem  vault/certs/prod-cert.pem.age
vault/certs/prod-key.pem   vault/certs/prod-key.pem.age
```

Also worth mentioning, you can use your own Age identity to encrypt.
To do that, just copy you Age identity file to `vault/age.key` and
then run `vaultgen` as usual:

```bash
$ mkdir -p vault
$ cp stash/age.key vault/
$ vaultgen
```

If this is the first time you run it, `vaultgen` will generate all
the vault files as explained earlier except for `vault/age.key`. It
will then use your Age identity to encrypt all the generated files.
On the other hand, if you ran `vaultgen` before, the copy command
will have overwritten the `vault/age.key` `vaultgen` generated on
the first run but all the other vault files will be the same as the
ones produced by the last `vaultgen` run. In this case, `vaultgen`
will use your Age identity to regenerate all the `.age` files but
leave be any other file—so e.g. your passwords will stay the same,
only the encrypted password files will change.


### Advanced usage

As we've seen earlier, running `vaultgen` without any argument makes
the command prompt you for passwords. This isn't what you want if
you'd like to run the command in batch mode—i.e. without requiring
user interaction. But there's a subcommand for each password that
lets you specify the password as an argument or generates one if
you don't pass the cleartext password as an argument. This way, you
can easily use `vaultgen` in scripts where no user interaction is
possible or wanted. For example, here's how you'd call `vaultgen`
to make it use a password of `UtmostJurorImmerseAnteaterStifflyPranker`

```bash
$ rm -rf vault/passwords/admin.*
$ vaultgen admin UtmostJurorImmerseAnteaterStifflyPranker
```

If you pass in no cleartext password, i.e. run `vaultgen admin` on
its own, then `vaultgen` generates a strong, memorable password for
the NixOS admin user, with a similar pattern to the prank one above.
The subcommands for the other passwords are: `root`, `odoo-admin`,
`pgadmin-admin`.

There's a subcommand for certificates as well: `certs`. This one
takes a list of CNs as arguments and generates a pub cert and key
for each CN in the list, then signs each cert with the vault CA.
For example,

```bash
$ vaultgen certs you.host my.site
```

generates a pub cert and key for both the `you.host` and `my.site`
CN as well as the corresponding Age-encrypted files—`.age` files.
If you pass in no CNs, i.e. run `vaultgen certs` on its own, then
`vaultgen` generates the cert files for the `localhost` CN.

Finally, there's a couple of subcommand to help develop `vaultgen`
itself. The `graph` subcommand prints a file dependency graph to
`stdout` in DOT (Graphviz) format. This is an example graph that
shows how the Makefile `vaultgen` uses (see *Implementation notes*
below) handles dependencies among vault files. If you have `dot`,
you can easily generate an SVG file to visualise the graph

```bash
$ vaultgen graph | dot -Tsvg -o deps-graph.svg
```

Otherwise, you could copy-paste `vaultgen graph`'s output into an
online Graphviz service like
- https://dreampuf.github.io/GraphvizOnline

The other subcommand to help with development is `mk`. This one lets
you call `make` on our Makefile directly with the extra args you give
to the subcommand. For example, to see what `make` actually does under
the bonnet, use

```bash
$ vaultgen mk --debug=v,w
```


### Implementation notes

The `vaultgen` command is a Bash [script][driver] that can run both
in interactive and batch mode and exports functions to implement the
subcommands documented earlier. The Nix [package][pkg] makes the script
available as `vaultgen`.

The implementation of the Bash script is trivial. It's just a frontend
to a [Makefile][mk] that builds generic vault files using static rules
to generate vault files that are always required, plus a bunch of generic
rules to generate passwords and certificates dynamically. In turn,
the Makefile delegates the implementation of the rules to a Bash
[library][lib].

Have a look at the docs in each of the files referenced above for
the implementation details.




[driver]: ./driver.sh
[lib]: ./lib.sh
[login]: ../../modules/login/docs.md
[mk]: ./Makefile
[module]: ../../modules/vault/docs.md
[pkg]: ./pkg.nix
