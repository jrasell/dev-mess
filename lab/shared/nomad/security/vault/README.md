# Vault
URL: https://developer.hashicorp.com/vault
Docs: https://developer.hashicorp.com/vault/docs

## vault-dev
The `vault-dev` runs a single pre-configured Vault server that can be used for testing and
development purposes. It supports setting the root key for ease of use and Vault is automatically
unsealed on startup.

## vault-ha
The `vault-ha` job runs a three-node Vault cluster using
[Integrated Storage (Raft)](https://developer.hashicorp.com/vault/docs/configuration/storage/raft)
as the backend. Each node is deployed in its own task group so that it can claim a dedicated
dynamic host volume (DHV) for persistent Raft data.

Register the three dynamic host volumes before submitting the job:
```shell
nomad volume create volumes/vault-1.volume.hcl
nomad volume create volumes/vault-2.volume.hcl
nomad volume create volumes/vault-3.volume.hcl
```
