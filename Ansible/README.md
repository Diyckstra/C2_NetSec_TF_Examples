Initial configuring Check Point servers
=========

This role pre-configures Check Point servers and runs the First Time Wizard.

Requirements
------------

Ansible >= 2.15.0

    ansible-galaxy collection install -r requirements.yml
    ansible-galaxy collection verify -r requirements.yml

Role Variables
--------------

The following variables must be defined:
- `valid_ips` -  variable must define a list of IP addresses or networks from which access will be made (it is also necessary for the ansible client to be in this list);
- The `SecurityGateways` or `SecurityManagementServer` group must be defined for the host;
- `hostname` variable must be defined, which will contain the host name;
- `ansible_host` - server ip address;
- `admin_password` - the password that will be set for the admin user;
- `expert_password` - the password that will be set for the expert;
- `grub2_password` - the password that will be set for the grub2;
- `api_password` - the password that will be set for the user `ansible` from which the connection to the server will be made.

Launch example Playbook
----------------

    ansible-playbook playbook.yml -i inventory.yml

Troubleshooting
---------------

A situation may arise when SMS hangs and host access is not allowed. In this case, you need to run a playbook with the `mgmt` tag:

    ansible-playbook playbook.yml -i inventory.yml -t mgmt


License
-------

BSD

Author Information
------------------
Anton Kurbatov
