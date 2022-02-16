# Nomad Local Development
This directory holds scripts and configuration which allow to automatic
building of a local environment for Nomad debugging and development. Thanks to
[HashiBox](https://github.com/nunchistudio/hashibox) for the inspiration and
base.

### Requirements
The following applications are expected to be installed and available on your
local machine.
* [Vagrant](https://www.vagrantup.com/downloads) to automate virtual machines
* [Virtual Box](https://www.virtualbox.org/wiki/Downloads) to provide
underlying virtualization
* [Puppet Bolt](https://puppet.com/docs/bolt/latest/bolt_installing.html) to
automate machine installation and updates

### Running
The `make help` command provides help output on the available make targets that
can be used to build, update, and destroy the development environment.

### Assumptions
The [Vagrantfile](./Vagrantfile) currently uses a hardcoded value for mounting
the Nomad codebase into the machine. Please modify this as required until a
better solution arrives.

## Contributing
Any and all contributions are welcome. My current focus is on better scripts,
automatic TLS and ACLs, as well as automatic federation. Additional regions are
also welcome if you wish to have something more "local".
