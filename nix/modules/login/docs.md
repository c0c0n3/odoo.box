Login
-----
> Nix module docs.

This module lets you choose how the root and admin users can log
in. In cloud mode, these users can only log in over SSH with their
respective SSH identities. In standard mode, they can log in both
through TTY and SSH using passwords. Plus, they can also log in
over SSH using their respective identities. Have a look at the
[interface][iface] file for the available module options.


### Cloud mode

In detail, for cloud mode, this module configures the root and
admin users
- with no passwords;
- with the (required) SSH login key specified through the
  [vault][vault] module.

Then it makes SSH + identity key the only way to log in.

### Standard mode
On the other hand, in standard mode, this module configures each
of these two users by
- setting the user's password to the respective hashed password
  specified through the [vault][vault] module;
- setting the user's SSH login key if one was specified through
  the [vault][vault] module;

and then lets users log in both through TTY and SSH using their
passwords, or, in the case of SSH, their SSH identity if one was
set in the [vault][vault] module.




[iface]: ./interface.nix
[vault]: ../vault/docs.md
