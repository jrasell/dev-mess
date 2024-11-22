# Nomad All-in-one Development
Configuration for running an all-in-one Nomad agent on a single machine with persistence of state. 
It is ideal for local development, testing, or learning and can be used with IDE debuggers and
[Delve](https://github.com/go-delve/delve). It requires having Nomad available locally within your
$PATH.

## europe-west-1 Region

Nomad server and client:
```console
nomad agent -config=europe-west-1_nomad.hcl
```

Bootstrap the ACLs using a pre-defined token (for dev purposes only):
```console
nomad acl bootstrap _nomad_root_token
```
