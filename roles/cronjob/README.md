# cronjob

A role to manage cronjobs.

Variable `cronjob_allow_list` and `cronjob_deny_list` allow you to manage the presence and content of the `/etc/cron.allow` and `/etc/cron.deny` files. See `man crontab` for details.

## What about existing crontabs for disallowed users?

If a user already has a crontab file in `/var/spool/cron/crontabs/` before you create `cron.allow`, that file will remain on disk, but the user will no longer be able to edit it or view it with `crontab -l`. The jobs will still run because the cron daemon reads the file directly from the spool directory.

You must delete these files manually; this role does not handle this task.
