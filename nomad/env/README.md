# Donkey
Donkey is a set of scripts and configuration which allows for the automatic
building and updating of a local environment for Nomad debugging and
development.

## Prerequisites
Donkey utilises a number of applications that are required to be installed
locally as well as some minimal configuration.

* Terraform 1.2.7 (required)
* Vagrant 2.3.0 (required)
* VirtualBox 6.1.32 (required)
* Ansible 2.10.17 (optional)
* TLS private key pair (required)

export TF_VAR_nomad_root_token=


## Ansible


### Common Commands


* Build the Nomad development code and replace the running binary:
```shell
ansible eu_west_2_servers \
  -i inventory/ansible --become-user "root"  \
  -a "bash /donkey/scripts/install_nomad.sh dev && bash /donkey/scripts/restart_nomad.sh"
```