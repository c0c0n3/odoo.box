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
      '';
    };
    odbox.backup.odoo.hot-schedule = mkOption {
      type = listOf str;
      default = [ "11:00:00" "14:00:00" "16:00:00" ];
      description = ''
        Schedule for the hot Odoo backups, i.e. backups performed
        while Odoo is running. Typically you'd back up a few times
        daily during business hours. For example: daily at 11AM,
        2PM and 4PM.

        Each schedule entry is a string in the systemd time format,
        see systemd.time(7) for the details. For each schedule entry
        you add to the list, there'll be a corresponding `OnCalendar`
        directive in the systemd unit file. This way you can easily
        schedule multiple runs in an intuitive way, e.g.

            hot-schedule = [ "11:00:00" "14:00:00" "16:00:00" ];

        for three daily runs at 11AM, 2PM and 4PM, instead of using
        the more cryptic

            hot-schedule = [ "11,14,16:00:00" ];

        Notice you can use `systemd-analyze` to check your schedule
        spec is valid and also display the actual schedule systemd
        will follow, e.g.

            systemd-analyze calendar "11,14,16:00:00" --iterations 9
      '';
    };
  };
}
