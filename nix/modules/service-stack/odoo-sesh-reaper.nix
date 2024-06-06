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
  description = ''
    Odoo session reaper deletes sessions that have been inactive for
    longer than ${mins} mins.
  '';

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
# 1. Odoo session lifecycle. When you hit Odoo w/o having logged in,
# you get a 90-day-valid anon session cookie `a` which you can only
# really use to access the login page and download pub assets like
# images and CSS. There's a corresponding serialised session state
# `s(a)` Odoo stores under `data/sessions`.
# - https://github.com/odoo/odoo/blob/tmp.14.0/odoo/http.py#L1456
# If you don't log in, `s(a)` doesn't get deleted until the session
# GC procedure kicks in, which is the next time someone logs in after
# one week:
# - https://github.com/odoo/odoo/blob/tmp.14.0/odoo/http.py#L1152
# - https://github.com/odoo/odoo/blob/tmp.14.0/odoo/http.py#L1372
# But if you log in, you get a 90-day-valid authenticated session
# cookie `c` and a corresponding serialised session `s(c)` whereas
# `s(a)` gets deleted. When you log out, Odoo deletes `s(c)` but it
# redirects you to the login page, so you get a fresh anon cookie `a'`
# and session state `s(a')`. So the session dir will fill up w/ junk
# over time. If you don't log out and just close the browser window,
# you'll still be able to use your cookie `c` for at least a week as
# inactive sessions are garbage-collected on a weekly-basis:
# - https://github.com/odoo/odoo/blob/tmp.14.0/odoo/http.py#L1152
# - https://github.com/odoo/odoo/blob/tmp.14.0/odoo/http.py#L1372
#
# 2. Disabling Odoo session GC. Turns out you can stop Odoo from
# deleting inactive sessions after a week:
# - https://github.com/odoo/odoo/blob/tmp.14.0/odoo/http.py#L1164-L1169
# This means session can last as long as 90 days. Of course, you'll
# have to clean up stale sessions yourself, but that we'd have to do
# anyway since Odoo seems to leak session state, so even with the GC
# procedure in place, you could wind up with one gazillion files in
# `data/sessions`. Too many files in there also means slow directory
# access which in turn means Odoo slows down too since it has to check
# session state on each call.
#
# 3. Inactive sessions. Every time you hit Odoo with a valid session
# cookie `c`, the corresponding serialised session state `s(c)` gets
# updated. This means we've got an easy way to figure out how long a
# session has been inactive: just look at the last-modified file attr
# of `s(c)`.
