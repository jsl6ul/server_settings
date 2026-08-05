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

This role apply rules defined in the `firewalld_rules` variable.  If
you have multiple instances of `firewalld_rules`, one solution is to
use `community.general.merge_variables` to merge them all
together. For example:

- `host_vars/syslog01.yml`

  ```
  firewalld_rules_syslog01:
    - name: syslog
      sources:
        - 192.168.0.0/16
      ports:
        - 514/tcp
        - 514/udp
  ```

- `group_vars/all/dhcp.yml`

  ```
  firewalld_rules_all_dhcp:
    - name: dhcp offer/ack/nak
      sources: [0.0.0.0/0]
      ports: [68/udp]
  ```

- `group_vars/all/merge_variables.yml`

  ```
  firewalld_rules: "{{ lookup('community.general.merge_variables', '^firewalld_rules_.*', initial_value=[]) }}"
  ```

for more information about `community.general.merge_variables`:
https://docs.ansible.com/projects/ansible/latest/collections/community/general/merge_variables_lookup.html
