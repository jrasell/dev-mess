# Nomad Multi-region Development Cluster
Configuration and helpful specifications for running Nomad multi-region on a single machine. It
runs 1 server and 1 client per region and is ideal for local development, testing, or learning. It
requires having Nomad available locally within your $PATH and a terminal with many tabs and windows.

## Authoritative Region (europe-west-1)
The authoritative region should be started and bootstrapped first.

Nomad server:
```console
nomad agent europe-west-1_nomad_server.hcl
```

Nomad client:
```console
nomad agent europe-west-1_nomad_client.hcl
```

Bootstrap the ACLs using a pre-defined token (for dev purposes only):
```console
nomad acl bootstrap _nomad_root_token
```

## Federated Regions (us-east-1, asia-south-1)
Once the authoritative region has been started and bootstrapped, the federated regions can be
started.

Nomad `us-east-1` server:
```console
nomad agent us-east-1_nomad_server.hcl
```

Nomad `us-east-1` client:
```console
nomad agent us-east-1_nomad_client.hcl
```

Nomad `asia-south-1` server:
```console
nomad agent asia-south-1_nomad_server.hcl
```

Nomad `asia-south-1` client:
```console
nomad agent asia-south-1_nomad_client.hcl
```

The federated regions can then be joined with the authoritative region:
```
nomad server join 127.0.0.1:9002 127.0.0.1:10002
```

#### Environment Variables
If you wish to interact directly with each region, you can export the following environment
variables in separate terminals.

Environment variables for `europe-west-1`:
```console
export NOMAD_ADDR=http://localhost:4646
export NOMAD_TOKEN=a9f9658b-49d3-697c-4469-bae37352e165
export NOMAD_REGION=europe-west-1
```

Environment variables for `us-east-1`:
```console
export NOMAD_ADDR=http://localhost:9000
export NOMAD_TOKEN=a9f9658b-49d3-697c-4469-bae37352e165
export NOMAD_REGION=us-east-1
```

Environment variables for `asia-south-1`:
```console
export NOMAD_ADDR=http://localhost:10000
export NOMAD_TOKEN=a9f9658b-49d3-697c-4469-bae37352e165
export NOMAD_REGION=asia-south-1
```
