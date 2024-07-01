Backups
-------
> Keeping our data for posterity.


Thanks to our Nix-powered GitOps approach, backing up and restoring
a machine is a breeze. Except for the data in the Odoo DB and file
store, our repo contains everything you need to instantiate our Odoo
Box. For that reason, all we need to back up is the Odoo DB and file
store using our backup NixOS module as explained below. If you have
a snapshot of the Odoo DB and file store at a point in time, you can
restore your machine to the exact same state it was at that point in
time with just a couple of commands.


### Backing up Odoo data

We've developed a [backup NixOS module][module] to help stash away
Odoo data. The module automatically extracts both the Odoo DB and
file store to a directory you choose at regular intervals you can
also configure. Plus, it lets you take both hot and cold backups.
A hot backup happens while Odoo is running and, for that reason,
isn't necessarily going to give you a consistent DB and file store
state when you restore it. On the other hand, a cold back up will
give you a consistent state since the module temporarily stops Odoo
while it's extracting the data. The [module docs][module] explain
how to enable and configure backups.


### Restoring a machine

Restoring a machine to its original state is a no-brainer. All you
need to do is
1. Deploy the prod NixOS config. Here you'd use the Flake as it was
   in the repo at the time the backup was taken.
2. Mount the backup volume on the backup dir configured in the
   [backup NixOS module][module].
3. Start the restore systemd service the [backup NixOS module][module]
   installs: `sudo systemctl start odoo-restore-backup`.




[module]: ../nix/modules/backup/docs.md
