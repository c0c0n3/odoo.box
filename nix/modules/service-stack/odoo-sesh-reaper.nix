#
# Grimly scythe inactive Odoo sessions.
#
# This service deletes any Odoo session that's been inactive for
# longer than the given number of minutes. This service runs every
# hour on the hour.
#
{
  # Odoo system username.
  odoo-usr,
  # Sessions inactive for longer than these many minutes get deleted.
  older-than
}:
let
  session-dir = "$STATE_DIRECTORY/data/sessions";
  mins = toString older-than;
  run = ''
    find "${session-dir}" -type f -mmin +${mins} -exec rm -f {} +
  '';                                                          # (3)
  schedule = [ "*-*-* *:00:00" ];
in {
  description = "Odoo session reaper deletes sessions that have been "
              + "inactive for longer than ${mins} mins.";

  wantedBy = [ "multi-user.target" ];

  script = run;

  serviceConfig = {
    Type = "oneshot";
    DynamicUser = true;
    User = odoo-usr;
    StateDirectory = odoo-usr;
  };

  startAt = schedule;
}
# NOTE
# ----
# 1. Odoo session lifecycle.
# See:
# - https://github.com/c0c0n3/odoo.box/pull/25#issuecomment-2152662861
#
# 2. Disabling Odoo session GC.
# See:
# - https://github.com/c0c0n3/odoo.box/pull/25#issuecomment-2152662861
#
# 3. Inactive sessions.
# See:
# - https://github.com/c0c0n3/odoo.box/pull/25#issuecomment-2152662861
#
