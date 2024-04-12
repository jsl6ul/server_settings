# ssh_authorized_keys

A simple role to manage authorized ssh keys.

# Merging ssh_authorized_keys

All instances of `ssh_authorized_keys` variable are merged.

`ssh_authorized_keys` from `group_vars/all`, `group_vars/all/ssh_authorized_keys`, the host's `host_vars` file and all `group_vars` of which the host is a member.

