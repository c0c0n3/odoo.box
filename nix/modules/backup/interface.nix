#
# See `docs.md` for module documentation.
#
{ config, lib, pkgs, ... }:

with lib;
with types;

{
  options = {
    odbox.backup.basedir = mkOption {
      type = path;
      default = "/backup";
      description = ''
        The base directory where all backup files go.
      '';
    };
    odbox.backup.odoo.enable = mkOption {
      type = bool;
      default = false;
      description = ''
        Enable it to automatically back up the Odoo DB and file store.
        Backups get scheduled at regular intervals and every time a
        backup fires, we dump the Odoo DB into a SQL file and put the
        file in the `odoo` directory under the backup base directory.
        We also sync the whole file store from the Odoo live store to
        a corresponding subdirectory of `odoo`.

        Notice each backup run overrides the files of the previous.
        You have to set up an EBS policy to actually take snapshots
        after each backup run. Also, you should compress and encrypt
        snapshots as we don't do that at the moment.

        We do both hot and cold backups. The hot backups dump the DB
        and sync the file store while Odoo is running, whereas a cold
        one stops Odoo before backing up and then restarts it as soon
        as the backup is done. Notice that a hot backup may result in
        an inconsistent DB and file store when restored, whereas cold
        backups are safe to restore.

        Finally enabling this module also installs a convenience systemd
        service to restore backups. The service takes the backup DB dump
        and file store and turns them into the live Odoo DB and file store,
        respectively. Notice systemd will never start this service, the
        sysadmin is meant to start it manually when they want to restore
        a backup like so: `sudo systemctl start odoo-restore-backup`.
      '';
    };
    odbox.backup.odoo.hot-schedule = mkOption {
      type = listOf str;
      default = [ "11:00:00" "14:00:00" "16:00:00" ];
      description = ''
        Schedule for the hot Odoo backups, i.e. backups performed
        while Odoo is running. Each schedule entry is a string in
        the systemd time format and for each entry you add to the
        list, there'll be a corresponding `OnCalendar` directive
        in the systemd unit file.
      '';
    };
    odbox.backup.odoo.cold-schedule = mkOption {
      type = listOf str;
      default = [ "02:00:00" ];
      description = ''
        Schedule for the cold Odoo backups, i.e. backups performed
        while Odoo has been stopped. Each schedule entry is a string
        in the systemd time format and for each entry you add to the
        list, there'll be a corresponding `OnCalendar` directive in
        the systemd unit file.
      '';
    };
  };
}
