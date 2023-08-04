# Lima
[Lima](https://github.com/lima-vm/lima) provides virtual machines for MacOS, which is particularly
useful when running Apple Silicon.

## Installation
In order to run the Lima VMs, you will need `lima` and `socket_vmnet` installed. This can be
performed by running `brew install lima && brew install socket_vmnet`.

To run `socket_vmnet` correctly, I needed to modify the default configuration file at
`/Users/jrasell/.lima/_config/networks.yaml` and replace the uncommented `socketVMNet:` line to
use a non-symlinked path. My replacement line is
`socketVMNet: /opt/homebrew/Cellar/socket_vmnet/1.1.2/bin/socket_vmnet`. You should then run the
commands [detailed here](https://github.com/lima-vm/socket_vmnet#lima).

## Running
The current setup requires mounting well known, local directories into the VM in order to perform
bootstrapping. It is therefore required to clone this repository into `~/Projects/Infra/dev-mess`
locally to use the [all-in-one VM](./nomad-in-one-ubuntu-jammy-arm64.yaml), and
[Nomad](https://github.com/hashicorp/nomad) into `"~/Projects/Go/nomad"` to use the
[dev VM](./nomad-dev-ubuntu-jammy-arm64.yaml).

### VMs
The available VMs have opinions and are used for various aspects of Nomad engineering life. They
are not perfect, but aim to form a base.

#### Nomad Dev
The [Nomad Dev](./nomad-dev-ubuntu-jammy-arm64.yaml) VM provides a basis for Nomad development and
includes an installation of Go. It is useful when quickly iterating on Nomad changes and testing via
the dev agent, while needing a Linux base. It can be started by running
`limactl start ~/Projects/Infra/dev-mess/lima/nomad-dev-ubuntu-jammy-arm64.yaml`.

#### Nomad All-In-One
The [Nomad All-In-One](./nomad-in-one-ubuntu-jammy-arm64.yaml) provides a VM that is running a Nomad
agent in both server and client mode. This is useful when debugging jobs or issues that require
Linux, persistence of state, and general non-dev mode behaviour. It can be started by running
`limactl start ~/Projects/Infra/dev-mess/lima/nomad-in-one-ubuntu-jammy-arm64.yaml`.
