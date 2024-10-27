CP_SG_FTW
=========

This role does the following:
- sets the password grub2
- sets the password expert
- limits access to the server by the list of addresses or networks
- sets the hostname
- sets the connection banner
- sets the timezone
- sets the NTP servers
- sets the DNS servers
- disables IPv6
- runs the First time wizard
- starts receiving the list of available update packages

Requirements
------------

Ansible >= 2.14.0
The Check Point server should have **Gaia API >=v1.7** engine installed on. More information can be found at [Gaia REST API SK](https://sc1.checkpoint.com/documents/latest/GaiaAPIs/).


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

The following variables can be redefined:
- `ntp_1` - IP address of the first NTP server;
- `ntp_2` - IP address of the second NTP server;
- `dns_1` - IP address of the first DNS server;
- `dns_2` - IP address of the second DNS server;
- `dns_3` - IP address of the third DNS server;
- 'dns_suffix' - dns suffix;
- `timezone` - time zone.

Example Playbook
----------------

    - name: Start Fist Time Wizard for Check Point
      hosts: checkpoint_servers
      gather_facts: false
      vars:
        ansible_connection: httpapi
        ansible_httpapi_use_ssl: true
        ansible_httpapi_validate_certs: false
        ansible_network_os: check_point.gaia.checkpoint
        ansible_user: "{{ user }}"
        ansible_password: "{{ password }}"
      roles:
        - role: CP_SG_FTW

License
-------

BSD

Author Information
------------------
Anton Kurbatov
[Tom Preston-Werner](https://tom.preston-werner.com/)
[Source on ansible galaxy](https://galaxy.ansible.com/ui/repo/published/check_point/gaia/)
[Source on github](https://github.com/CheckPointSW/CheckPointAnsibleGAIACollection)