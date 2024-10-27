Upgrade_CP_Gaia_API_1.7
=========

This role updates the GAIA API engine from version 1 to 1.6 to 1.7.

Example Playbook
----------------

    - hosts: servers
      roles:
         - { role: username.rolename, x: 42 }

    - name: Upgrade Gaia API to 1.7
      hosts: checkpoint_servers
      gather_facts: false
      connection: ssh
      vars:
        ansible_port: 22
        ansible_user: "{{ user }}"
        ansible_password: "{{ password }}"
        ansible_ssh_common_args: '-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no'
        ansible_python_interpreter: /usr/bin/python3
      roles:
        - role: Upgrade_CP_Gaia_API_1.7

License
-------

BSD

Author Information
------------------
Anton Kurbatov
[SK for upgrade](https://support.checkpoint.com/results/sk/sk143612)
