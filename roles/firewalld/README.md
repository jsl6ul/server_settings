# firewalld

A role for configuring firewalld using a YAML structure.

This role does not use the usual firewalld zones. All rules are placed 
in the public zone, and restrictions are based on the source address 
and destination port.

```
firewalld_rules:
  - name: allow some icmp
    sources: [0.0.0.0/0]
    family: ipv4
    icmps:
      - echo-request
      - echo-reply
      - fragmentation-needed
      - time-exceeded
      - destination-unreachable
    limit: 10/s

  - name: ssh from proxyjump
    sources:
      - 192.168.0.10/32   # proxyjump1
      - 192.168.0.11/32   # proxyjump2
    services:
      - ssh

  - name: node_exporter from monitoring
    sources:
      - 192.168.0.23/32   # prometheus server
    ports:
      - 9100/tcp

  - name: dhcp offer/ack/nak
    sources: [0.0.0.0/0]
    ports: [68/udp]
```

# Merging firewalld_rules

All instances of the `firewalld_rules` variable are merged.

The default ansible operation is to overwrite variables with the "nearest" one.
https://docs.ansible.com/ansible/latest/user_guide/playbooks_variables.html#understanding-variable-precedence

For the `firewalld_rules` variable, we want to merge it if it is present in several `group_vars` files.

This allows us to define the same `firewalld_rules` variable in several files, for example: `all.yml`, 
the `login.yaml`, and the `host_vars`. The rules defined in these three files will all be applied on the 
host (rather than only those defined in the `host_vars` overwriting those in the `group_vars`).

This avoids having variable names by "floor" (ie. `firewalld_rules_all, firewalld_rules_group, firewalld_rules_host`).

The principle is relatively simple: the tasks defined in the `tasks/main.yml` file perform **include_vars** 
of all vars files related to the host. It then performs an `set_fact` to merge all instances of the `firewalld_rules` variable.

There is always a risk of collision. If the same rule is defined in two places, it will 
be applied twice, without error. This is not an error in itself, but not necessarily the objective. 
Maybe we should add collision detection, and do an assert to cause an ansible error, so that it doesn't go unnoticed.
