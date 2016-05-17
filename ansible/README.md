# Ansible Configuration for Tranzmt.it deployment

This directory contains all the Ansible configuration for deploying Tranzmt,
including keys and password hashes for the users on the machines.

# Basic usage

The basic runthrough from scratch is:

1. Set up your hosts file (see hosts.example).
2. With the username you can ssh to the target box with, run `./pre_install $username`.
3. Run the user setup script once the pre install has finished with `./user_maintenance`

# User Adition

Add users to the `group_vars/all` file, then set which ones have ansible access
and who else to install with `ansible_ssh_users` and `deploy_users` - see
`group_vars/production` for an example. To generate a password for use, use the
following command:

```
mkpasswd --method=SHA-512
```

If you do not have mkpasswd, then [try these instructions][gen-password] (from
the Ansible instructions themselves).

[gen-password]: http://docs.ansible.com/ansible/faq.html#how-do-i-generate-crypted-passwords-for-the-user-module

# Playbooks

This section details the various playbooks which are in this Ansible Config

## Pre Install

The pre install config is used for bootstrapping a machine to be usable with
Ansible. This creates an Ansible user, with the UID/GID of 1005, and user/group
name of ansible. This user will then be granted passwordless sudo to ease use
of Ansible without sharing sudo passwords for it.
