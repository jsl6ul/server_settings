# ssh_authorized_keys

A simple role to manage authorized ssh keys.

# Merging ssh_authorized_keys

All instances of `ssh_authorized_keys` variable are merged.

- `group_vars/all.yml`
- `group_vars/all/ssh_authorized_keys.yml`
- `host_vars/{{ inventory_hostname }}.yml`
- `host_vars/{{ inventory_hostname }}/ssh_authorized_keys.yml`
- and all `group_vars/*.yml` of which the host is a member.

The default ansible operation is to overwrite variables with the "nearest" one.
[understanding-variable-precedence](https://docs.ansible.com/ansible/latest/user_guide/playbooks_variables.html#understanding-variable-precedence)

Here, we want to merge it if it is present in several `vars` files. 
The principle is relatively simple: the tasks perform an **include_vars** of all vars files related to the host and perform an `set_fact` to merge all instances of `ssh_authorized_keys`.
