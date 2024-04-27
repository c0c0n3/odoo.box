Vault
-----
> Nix module docs.

This module groups together all our password and TLS settings.
Other modules read the values this module config holds to set up
passwords, TLS, etc. for services and users. As such, this module
defines an [interface][iface] to access secrets.

Typically, you don't set directly yourself the options this module
defines. Rather you enable one of the implementation modules detailed
below which actually set this module's options after retrieving and
extracting the needed secrets.


### Agez implementation

Age-backed vault. This module configures the vault with passwords
and certificates extracted from Age-encrypted files. You specify
which Age-encrypted files to use through the [odbox.vault.age][age-files]
options and deploy the Age identity file to the target machine at
`/etc/age.key`—this is the default path where Agez expects the file
to be, but you can change it with the `odbox.vault.agez.key` option.
On NixOS config deployment, Agez uses the given Age identity to decrypt
your secrets on a `tmpfs` file system so other modules can access
them but they never wind up in permanent storage. Also Agez assigns
proper permissions so only the users who actually need the secrets
have access to them.

Notice we initially developed this module for testing and debugging
Age encryption. Turns out the implementation is actually rock-solid,
but not as flexible as Agenix—well, except for the ability to use
a directory tree to organise your decrypted secrets. Anyway, you'd
probably want to use the Agenix implementation instead of Agez—see
below.

### Example usage
First off you need to prep the secrets you'd like to use. Typically
you do that by running the [vaultgen][vaultgen] command, but there's
nothing stopping you from doing it in any other way you fancy. Once
you have generated Age-encrypted files, you tell Agez where to find
them using the [odbox.vault.age][age-files] options and then enable
the Agez implementation as in the example below.

```nix
odbox = {
  vault = {
    age = {
      root-pwd = ./vault/passwords/root.yesc.age;
      admin-pwd = ./vault/passwords/admin.yesc.age;
      odoo-admin-pwd = ./vault/passwords/odoo-admin.age;
      pgadmin-admin-pwd = ./vault/passwords/pgadmin-admin.age;
      nginx-cert = ./vault/certs/localhost-cert.pem.age;
      nginx-cert-key = ./vault/certs/localhost-key.pem.age;
    };
    agez.enable = true;
  };
};
```

Before you deploy this config, you've got copy the Age identity in
`vault/age.key` to the target machine where Agez expects to find it.
If you haven't changed it, the default location is `/etc/age.key` so
you'd normally copy over the identity file like this:

```bash
$ scp vault/age.key root@target.machine:/etc/
```


### Agenix implementation

Agenix-backed vault. This module configures the vault with passwords
and certificates extracted from Age-encrypted files. You specify
which Age-encrypted files to use through the [odbox.vault.age][age-files]
options and deploy the Age identity file to the target machine at
`/etc/age.key`—this is the default path where Agez expects the file
to be, but you can change it with the `odbox.vault.agenix.key` option.
On NixOS config deployment, Agenix uses the given Age identity to
decrypt your secrets on a `tmpfs` file system so other modules can
access them but they never wind up in permanent storage. Also Agenix
assigns proper permissions so only the users who actually need the
secrets have access to them.

Notice Agenix is a better and more flexible solution than the Agez
one we developed ourselves. So you should use Agenix and only resort
to Agez if you need to debug something. (In fact, that's the reason
why we developed Agez.)

### Example usage
First off you need to prep the secrets you'd like to use. Typically
you do that by running the [vaultgen][vaultgen] command, but there's
nothing stopping you from doing it in any other way you fancy. Once
you have generated Age-encrypted files, you tell Agenix where to find
them using the [odbox.vault.age][age-files] options and then enable
the Agenix implementation as in the example below.

```nix
odbox = {
  vault = {
    age = {
      root-pwd = ./vault/passwords/root.yesc.age;
      admin-pwd = ./vault/passwords/admin.yesc.age;
      odoo-admin-pwd = ./vault/passwords/odoo-admin.age;
      pgadmin-admin-pwd = ./vault/passwords/pgadmin-admin.age;
      nginx-cert = ./vault/certs/localhost-cert.pem.age;
      nginx-cert-key = ./vault/certs/localhost-key.pem.age;
    };
    agenix.enable = true;
  };
};
```

Before you deploy this config, you've got copy the Age identity in
`vault/age.key` to the target machine where Agenix expects to find it.
If you haven't changed it, the default location is `/etc/age.key` so
you'd normally copy over the identity file like this:

```bash
$ scp vault/age.key root@target.machine:/etc/
```


### Snake oil implementation

Snake oil vault. This module configures the vault with clear-text
passwords and certs for testing with the dev VM. The values come
from the [snake oil security package][snake], see there for the
details.

**WARNING**: only ever enable this vault implementation for testing
locally with the dev VM.

### Example usage
The only thing you need to do is enable this vault implementation

```nix
odbox.vault.snakeoil.enable = true;
```

There's no files you have to supply since the implementation sources
them from the [snake oil security package][snake].




[age-files]: ./age-files.nix
[iface]: ./interface.nix
[snake]: ../../pkgs/snakeoil-sec/docs.md
[vaultgen]: ../../pkgs/vaultgen/docs.md
