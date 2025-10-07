# Nomad Server Cluster
Configuration for running a Nomad server cluster on a single machine. It runs 3 server agents and is
ideal for local development, testing, or learning. It requires having Nomad available locally within
your $PATH and a terminal with many tabs and windows.

Nomad server 1:
```console
nomad agent -config euw1_nomad_server_1.hcl
```

Nomad server 2:
```console
nomad agent -config euw1_nomad_server_2.hcl
```

Nomad server 3:
```console
nomad agent -config euw1_nomad_server_3.hcl
```

Bootstrap the ACLs using a pre-defined token (for dev purposes only):
```console
nomad acl bootstrap _nomad_root_token
```
