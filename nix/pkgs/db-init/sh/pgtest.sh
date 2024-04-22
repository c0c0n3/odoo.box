#!/bin/bash
# ^ The Nix derivation replaces the shebang with a suitable one.

#
# See `docs.md` for script documentation.
#

# Stop at the first error, especially if in a pipeline.
set -ueo pipefail


# Grab the Postgres service user if given in the env, otherwise
# default to the customary `postgres` user.
: "${PG_SVC_USR:=postgres}"


# Print the Postgres main process's PID and return 0 if Postgres is
# up and running; otherwise return a non-zero exit code.
is_running() {
    local pg_pid=$(
        ps -o pid=,ppid= -u ${PG_SVC_USR} | \
            grep ' 1$' |  tr -s ' ' | cut -d ' ' -f 2
    )
    echo "${pg_pid}" | grep '^[1-9][0-9]*$'
}
# NOTE
# 1. Process query. Notice that `ps` returns a non-zero exit code
# if the user argument isn't the name of an existing user or if
# that user has no associated running process. The `pipefail` option
# makes sure we exit right away if any of these the cases.
# 2. Postgres PID file. Why not just grab the PID from the PID file?
# E.g. `head -n 1 /var/lib/postgresql/15/postmaster.pid`? Well, the
# user who run this script may not have enough perms to actually get
# to that file. So we need a more complicated way to get the PID as
# explained below.
# 3. PID pipeline. Finds out what's the PID of the Postgres main
# process. This is the server processes that listens for connections
# and then forks child processes to do the work.
# Because we start Postgres through systemd, the main process will
# have a parent PID of 1. So we select the line in the `ps` output
# whose PPID field is 1 and get rid of extra spaces. This will leave
# us with a line in the format ` x 1` where x is the PID we're after.
# So we just need to select the second column in that line to extract
# our PID.


# Check if Postgres is running and in that case wait indefinitely
# until it accepts connections. On connecting, print out the Unix
# socket and/or TCP socket the server is listening to---e.g.
# `/run/postgresql:5432 - accepting connections`. Also return a 0
# exit code.
# On the other hand, stop and return a non-zero exit code if Postgres
# isn't running.
is_ready() {
    while ! pg_isready -t 3; do
        # Either there's Postgres process or the server's having a
        # slow start. Give it a chance to catch up.
        sleep 1
        is_running
        # ^this will return a non-zero code if there's no Postgres
        # process which, b/c of `set -e`, will break out of the loop.
    done
}
# NOTE
# ----
# 1. Sending signals. We can't use the usual trick of sending a 0
# signal to the Postgres main process as in the example code below:
#
#     # pg_pid=$(...same as in is_running... )
#     while ! pg_isready -t 3; do
#         if ! kill -s 0 "${pg_pid}"; then
#             exit 1
#         fi
#         sleep 0.1
#     done
#
# That's for two reasons. First off, the user who runs our script
# may not have permissions to send a signal to the Postgres process,
# so even if Postgres were up and running, the `kill` command would
# fail. Second, we could get into a (very unlikely) race condition
# where after reading the PID, but before calling the `kill` command,
# the Postgres server stops and restarts. In this case, the PID we
# read earlier could be associated to no process at all or even a
# new process that has nothing to do with Postgres!
# See also:
# - https://unix.stackexchange.com/questions/169898
# - https://unix.stackexchange.com/a/169970


# Call the function corresponding to the input argument or print an
# error message if the argument isn't one of the recognised values.
case "$1" in
    running)
        is_running
        ;;
    ready)
        is_ready
        ;;
    *)
        echo "unknown option: $1"
        exit 1
esac
