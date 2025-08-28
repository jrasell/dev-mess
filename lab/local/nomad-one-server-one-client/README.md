# Nomad One Server and One Client
Configuration for running a single Nomad server and a single Nomad client as separate agents on a
single machine with persistence of state. It requires having Nomad available locally within your
$PATH.

## europe-west-1 Region

Nomad server:
```console
nomad agent -config=europe-west-1_server.hcl
```

Nomad client:
```console
nomad agent -config=europe-west-1_client.hcl
```

Bootstrap the ACLs using a pre-defined token (for dev purposes only):
```console
nomad acl bootstrap _nomad_root_token
```
