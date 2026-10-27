# Nomad
URL: https://developer.hashicorp.com/nomad
Docs: https://developer.hashicorp.com/nomad/docs

Nomad is a highly available, distributed, data-center aware cluster and application scheduler
designed to support the modern datacenter with support for long-running services, batch jobs, and
much more.

### cell
The `cell` directory contains Nomad job specifications to run "Nomad-on-Nomad" to help develop and
test cell based architectures.

The `nmd-srv-cell-dev.nomad.hcl` job provides the server cluster that should be started before the
respective client job.

The `nmd-ndms-cell-dev.nomad.hcl` job uses
[nomad-nodesim](https://github.com/hashicorp-forge/nomad-nodesim) to run simulated Nomad clients.
The clients only have the mock driver enabled and a shim alloc-runner, which allows for dense
placement on a small number of underlying hosts. The job requires specific Docker plugin
configuration options that allow mounts and additional container capabilities. The following snippet
can be used for testing:
```hcl
plugin "docker" {
  config {
    allow_privileged = true
    allow_caps       = ["all"]

    volumes {
      enabled = true
    }
  }
}
```

A quick way to test the cell jobs is to run the following commands in a terminal. It will configure
a Nomad namespace for the cell jobs, start the server job, and then start the client job.
```bash
nomad namespace apply eghm

CELL_REGION_SUFFIX=$(uuidgen | awk -F'-' '{print tolower($1)}')

nomad job run \
  -namespace=eghm \
  -var namespace=eghm \
  -var id_prefix=nmd-srv \
  -var nomad_agent_region=eghm-${CELL_REGION_SUFFIX} \
  cell/nmd-srv-cell-dev.nomad.hcl

nomad job run \
  -namespace=eghm \
  -var namespace=eghm \
  -var id_prefix=nmd-clnt \
  -var nomad_agent_region=eghm-${CELL_REGION_SUFFIX} \
  -var srv_id_prefix=nmd-srv \
  -var nomad_agent_allocs=3 \
  cell/nmd-ndms-cell-dev.nomad.hcl
```
