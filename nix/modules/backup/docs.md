Backup
------
> Nix module docs.

This [module][iface] automatically backs up the Odoo DB and file
store. It also installs a convenience systemd service to restore
a backup.


### Overview

Backups run at configurable intervals and every time a backup fires,
we dump the Odoo DB into a SQL file (using `pg_dump`) and sync the
Odoo backup file store with the live file store. All the backup files
get stored in a configurable backup area. Notice the syncing of the
file store happens through `rsync` which lets us efficiently mirror
the live file store as only file blocks that have changed since the
last backup actually get copied over from the live file store. Also,
any file deleted in the live store gets automatically deleted from
the mirror copy too.

Notice each backup run overrides the files of the previous. You have
to set up an EBS policy to actually take snapshots after each backup
run. Also, you should compress and encrypt snapshots as we don't do
that at the moment.

We do both hot and cold backups. The hot backups dump the DB and sync
the file store while Odoo is running, whereas a cold one stops Odoo
before backing up and then restarts it as soon as the backup is done.
Notice that a hot backup may result in an inconsistent DB and file
store when restored, whereas cold backups are safe to restore.

Have a look at these Nix files for the implementation details:
- [Odoo implementation entry point][odoo-mod]
- [Odoo backup script][odoo-backup-script]
- [Odoo hot/cold backup service builder][odoo-backup-svc]

Finally, we also install a convenience systemd service to restore
backups. The service takes the backup DB dump and file store and
turns them into the live Odoo DB and file store, respectively.
Notice systemd will never start this service, the sysadmin is meant
to start it manually when they want to restore a backup like so:

```bash
$ sudo systemctl start odoo-restore-backup
```

Have a look at these Nix files for the restore implementation:
- [Odoo implementation entry point][odoo-mod]
- [Odoo restore script][odoo-restore-script]
- [Odoo restore service builder][odoo-restore-svc]


### Backup area

Backups get written to a configurable directory. You specify where
this directory should be through the base directory option which
takes an absolute path—default: `/backup`. Notice the backup module
automatically assigns permissions so only root can access the backup
area. It also sets up an `odoo` directory under the base directory
where it stores all the Odoo backup files. Specifically, the `odoo`
directory contains the SQL dump file and a `filestore` directory
which mirrors the live file store contents. Here's an example of
the backup area contents:

```
/backup
└── odoo
   ├── filestore
   │  └── odoo_martel_14
   │     └── ...
   └── odoo_martel_14.dump.sql
```

Typically, you'd mount a separate, dedicated disk or partition on
the backup base directory path. For example, at the moment in prod
we mount an EBS volume on the backup directory. Even if you don't
set up a dedicated backup mount, backups will still work since the
module automatically creates the backup base directory on the root
file system if no directory exist at the configured backup path.
This comes in handy for testing with the dev VM where there's no
separate backup disk or partition.

Notice that the backup module streams data to the backup area. So
you won't need to cater for double the size of the live data on the
source partition (where the Odoo data sits) as it'd be the case if
the backup procedure first wrote all the files to that disk before
moving them to the backup area.


### Schedules

The module provides [options][iface] to schedule both hot and cold
backups. Typically you'd want to do a hot backup a few times a day
during business hours. For example: daily at 11AM, 2PM and 4PM. This
way, even if the backup isn't necessarily consistent when you restore
it, you've still got enough data to try reassembling the pieces. On
the other hand, the cold backup is a consistent one, but you wouldn't
want to run it during business hours as Odoo needs to go down. Likely
you'd make a cold backup once a day in the dead of the night—e.g.
daily at 2AM.

Both hot and cold backup options accept a list of schedules. Each
schedule is a string in systemd time format—see `systemd.time(7)`
for the details. For each schedule entry you add to the list, the
module generates a corresponding `OnCalendar` directive in the backup
systemd unit file. This way you can easily schedule multiple runs in
an intuitive way, e.g.

```nix
    [ "11:00:00" "14:00:00" "16:00:00" ]
```

for three daily runs at 11AM, 2PM and 4PM, instead of using the more
cryptic

```nix
    [ "11,14,16:00:00" ]
```

Notice you can use `systemd-analyze` to check your schedule spec is
valid and also display the actual schedule systemd will follow, e.g.

```bash
$ systemd-analyze calendar "11,14,16:00:00" --iterations 9
  Original form: 11,14,16:00:00
Normalized form: *-*-* 11,14,16:00:00
    Next elapse: Wed 2024-05-01 16:00:00 CEST
       (in UTC): Wed 2024-05-01 14:00:00 UTC
       From now: 3min 14s left
   Iteration #2: Thu 2024-05-02 11:00:00 CEST
       (in UTC): Thu 2024-05-02 09:00:00 UTC
       From now: 19h left
   Iteration #3: Thu 2024-05-02 14:00:00 CEST
       (in UTC): Thu 2024-05-02 12:00:00 UTC
       From now: 22h left
   Iteration #4: Thu 2024-05-02 16:00:00 CEST
       (in UTC): Thu 2024-05-02 14:00:00 UTC
       From now: 24h left
   Iteration #5: Fri 2024-05-03 11:00:00 CEST
       (in UTC): Fri 2024-05-03 09:00:00 UTC
       From now: 1 day 19h left
   Iteration #6: Fri 2024-05-03 14:00:00 CEST
       (in UTC): Fri 2024-05-03 12:00:00 UTC
       From now: 1 day 22h left
   Iteration #7: Fri 2024-05-03 16:00:00 CEST
       (in UTC): Fri 2024-05-03 14:00:00 UTC
       From now: 2 days left
   Iteration #8: Sat 2024-05-04 11:00:00 CEST
       (in UTC): Sat 2024-05-04 09:00:00 UTC
       From now: 2 days left
   Iteration #9: Sat 2024-05-04 14:00:00 CEST
       (in UTC): Sat 2024-05-04 12:00:00 UTC
       From now: 2 days left
```


### Example usage

```nix
  odbox = {
    backup = {
      basedir = "/backup";
      odoo = {
        enable = true;
        hot-schedule = [ "11:00:00" "14:00:00" "16:00:00" ];
        cold-schedule = [ "02:00:00" ];
      };
    };
  };
```

### AWS Lifecycle Manager - Volume snapshots

As we described on the **Backup Area** section, an EBS Volume
(`vol-0200287c009a32cdd`) is mounted on the `/backup` directory.
On the AWS console we created a `Data Lifecycle Rule (policy-07d599ae024e674c7)`
which basically defines a policy for snapshotting the volume on a
schedule basis. The first snapshot taken is a FULL clone of the volume,
then, all the other snapshots are incremental.

As of now, we implemented 2 different schedules:

**Daily**
- Frequency: Every 24 hours starting at 03:00 AM (UTC +2 - Zurich).
- Retention rule: Snapshots will be retained for 90 days.

On the 91st day a new FULL will be taken.

**Monthly**
- Frequency: On the 1st Monday every month starting at 03:00 AM
  (UTC +2 - Zurich).
- Retention rule: Snapshot will be retained in the standard tier
  for 30 days, then retained in the Archive tier for 90 days.




[iface]: ./interface.nix
[odoo-mod]: ./odoo/module.nix
[odoo-backup-script]: ./odoo/backup-script.nix
[odoo-backup-svc]: ./odoo/mk-backup-svc.nix
[odoo-restore-script]: ./odoo/restore-script.nix
[odoo-restore-svc]: ./odoo/mk-restore-svc.nix