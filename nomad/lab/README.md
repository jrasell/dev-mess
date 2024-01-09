# Lab
This directory contains configuration and scripts for running clustered Nomad
when development mode is not enough. This is particularly useful when using
Apple Silicon as your development machine, but require Linux capabilities
such as network namespaces.

## Requirements
[Canonical Multipass](https://multipass.run/) is used to provide base Ubuntu
machines for the cluster. The [installation guide](https://multipass.run/install)
can provide details on how to run this on your local operating system.

[Ansible](https://docs.ansible.com/) is used to perform machine bootstrapping
and configuration. As with Multipass, the
[installation guide](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)
can be used to ensure you have this available locally.

[direnv](https://direnv.net/) can be used to optionally load Nomad client
environment variables from the written `.envrc` file. This allows for easy local
connectivity to the Nomad API.

The cloud-init scripts currently install my public SSH key. If you are using
these scripts, you should update this to use your own key. The
[cloud-init](./multipass/cloud-init) directory contains the files you will need
to change.

The setup on my local network and Multipass requirements means each machine gets
two IP addresses. The first, `enp0s1`, is configured by Multipass and assigned
by DHCP which acts as our administrative access. The second, `enp0s2`, is
statically assigned via netplan and cloud-init. These IP addresses are custom to
my network and you might need to change them. This change can be made via the
[cloud-init scripts](multipass/cloud-init).

## Starting
Execute the [cluster-start](./cluster-start.sh) script from within this
directory, passing it a single argument which is the fully-qualified path to
a local copy of the Nomad codebase.
```
$ ./cluster-start.sh "/Users/jrasell/Projects/Go/nomad"
```

# Bootstrapping
Once the base instances are running, you can bootstrap the cluster, including
ACLs, by using the [cluster-bootstrap](./cluster-bootstrap.sh) script.
```
$ ./cluster-bootstrap.sh
```

## Deleting
To stop and delete the Multipass machines, you can execute the
[cluster-delete](./cluster-delete.sh) script from within this directory.
```
$ ./cluster-delete.sh
```
