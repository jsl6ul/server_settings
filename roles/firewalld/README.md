# firewalld

A role for configuring firewalld using a YAML structure.

This role does not use the usual firewalld zones. All rules are placed 
in the public zone, and restrictions are based on the source address 
and destination port.

# ICMP messages

There are two approaches to managing ICMP rules: globally for the zone, 
using `firewalld_icmp_block` and `firewalld_icmp_block_inversion`, 
or by source address, using `firewalld_rules`.

Take a look at `defaults/main.yml` for some examples.

https://firewalld.org/documentation/zone/options.html

# Merging firewalld_rules

All instances of the `firewalld_rules` variable are merged.

- `group_vars/all.yml`
- `group_vars/all/firewalld.yml`
- `host_vars/{{ inventory_hostname }}.yml`
- `host_vars/{{ inventory_hostname }}/firewalld.yml`
- and all `group_vars/*.yml` of which the host is a member.

The default ansible operation is to overwrite variables with the "nearest" one.
[understanding-variable-precedence](https://docs.ansible.com/ansible/latest/user_guide/playbooks_variables.html#understanding-variable-precedence)

For the `firewalld_rules` variable, we want to merge it if it is present in several files.

This allows us to define the same `firewalld_rules` in several files. The rules defined in these files 
will all be applied on the host (rather than only those defined in the "nearest" file).

The principle is relatively simple: the tasks perform an **include_vars** of all vars files related 
to the host. It then performs an `set_fact` to merge all instances of the `firewalld_rules`.

There is always a risk of collision. If the same rule is defined in two places, it will 
be applied twice, without error. This is not an error in itself, but not necessarily the objective. 
Maybe we should add collision detection, and do an assert to cause an ansible error, so that it doesn't go unnoticed.
