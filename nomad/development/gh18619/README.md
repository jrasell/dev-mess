# Nomad ACL Roles with Dangling Policies
This is the reproduction for [GH-18619](https://github.com/hashicorp/nomad/issues/18619) which
details erroneous permissions granted when an ACL role contains dangling ACL policies.

### Assumptions
- Nomad is running with the HTTP API available at `http://127.0.0.1:4646` and ACL's are enabled but
not bootstrapped.

1. Execute the setup script.
```shell
$ bash ./setup.sh
```

2. Generate an ACL token, and export the SecretID in another terminal for use
with the alloc exec commands.
```shell
$ nomad acl token create -ttl=10m -name=test-token -role-name=my-role-sre
``` 

3. Attempt to exec into the running allocation, this should succeed.
```shell
$ nomad alloc exec -namespace=system <ALLOC_ID> /bin/bash
```

4. Delete the `namespace-monitoring-admin` ACL policy.
```shell
$ nomad acl policy delete namespace-monitoring-admin
```

5. Attempt to exec into the running allocation.
```shell
$ nomad alloc exec -namespace=system <ALLOC_ID> /bin/bash
```

This attempt should return an error, which is erroneous as the ACL token has permission to allow
the capability.
```
failed to exec into task: rpc error: Permission denied
```

The Nomad agent logs contain useful log information detailing the permission denied error.
```
2023-10-02T14:20:16.141+0100 [DEBUG] http: request complete: method=GET path="/v1/allocations?namespace=system&prefix=18c3b4e1" duration="220.959µs"
2023-10-02T14:20:16.142+0100 [DEBUG] http: request complete: method=GET path=/v1/allocation/18c3b4e1-fd24-1f6f-0393-7de6bc0d0768?namespace=system duration="193.125µs"
2023-10-02T14:20:16.143+0100 [DEBUG] http: request failed: method=GET path=/v1/node/0b14e699-a99b-158f-9060-097f8696d2be?namespace=system error="Permission denied" code=403
2023-10-02T14:20:16.143+0100 [DEBUG] http: request complete: method=GET path=/v1/node/0b14e699-a99b-158f-9060-097f8696d2be?namespace=system duration="125.417µs"
2023-10-02T14:20:16.144+0100 [ERROR] client.rpc: error performing RPC to server: error="rpc error: Permission denied" rpc=ACL.GetPolicies server=127.0.0.1:4647
2023-10-02T14:20:16.144+0100 [ERROR] client.rpc: error performing RPC to server which is not safe to automatically retry: error="rpc error: Permission denied" rpc=ACL.GetPolicies server=127.0.0.1:4647
```
