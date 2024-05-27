Login
-----
> Nix module docs.

This module lets you choose how the root and admin users can log
in. In cloud mode, these users can only log in over SSH with their
respective SSH identities. In standard mode, they can log in both
through TTY and SSH using passwords. Plus, they can also log in
over SSH using their respective identities. Have a look at the
[interface][iface] file for the available module options.

Notice that NixOS automatically creates a root user, so we do the
same for the [admin user][builtin]. That is, we create the admin
user unconditionally. We do this because we'd also like to have a
built-in user who is normally a regular user but can get super-cow
powers through `sudo` when needed.


### Cloud mode

In detail, for [cloud mode][cloud], this module configures the root
and admin users
- with no passwords;
- with the (required) SSH login key specified through the
  [vault][vault] module.

Then it makes SSH + identity key the only way to log in.

#### Example usage

```nix
odbox = {
  login.mode = "cloud";    # default, can omit if you like
  vault = {
    root-ssh-file = ./path/to/root/id_ed25519.pub;
    admin-ssh-file = ./path/to/admin/id_ed25519.pub;
  };
};
```


### Standard mode

On the other hand, in [standard mode][standard], this module configures
each of these two users by
- setting the user's password to the respective hashed password
  specified through the [vault][vault] module;
- setting the user's SSH login key if one was specified through
  the [vault][vault] module;

and then lets users log in both through TTY and SSH using their
passwords, or, in the case of SSH, their SSH identity if one was
set in the [vault][vault] module.

#### Example usage

```nix
odbox = {
  login.mode = "standard";
  vault = {
    snakeoil.enable = true;    # can use Agez or Agenix instead
    # omit keys if you don't care about SSH key login
    root-ssh-file = ./vault/ssh/id_ed25519.pub;
    admin-ssh-file = ./vault/ssh/id_ed25519.pub;
  };
};
```




[builtin]: ./builtin-users.nix
[cloud]: ./cloud.nix
[iface]: ./interface.nix
[standard]: ./standard.nix
[vault]: ../vault/docs.md
