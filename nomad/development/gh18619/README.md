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

2. Delete the `namespace-monitoring-admin` ACL policy.
```shell
$ nomad acl policy delete namespace-monitoring-admin
```

3. Generate an ACL token, and export the SecretID in another terminal for use
with the alloc exec commands.
```shell
$ nomad acl token create -ttl=10m -name=test-token -role-name=my-role-sre
```

4. Attempt to exec into the running allocation.
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
2023-10-06T08:57:56.877+0100 [ERROR] client.rpc: error performing RPC to server: error="rpc error: Permission denied" rpc=ACL.GetPolicies server=127.0.0.1:4647
2023-10-06T08:57:56.877+0100 [ERROR] client.rpc: error performing RPC to server which is not safe to automatically retry: error="rpc error: Permission denied" rpc=ACL.GetPolicies server=127.0.0.1:4647
2023-10-06T08:57:56.877+0100 [INFO]  client: task exec session starting: exec_id=c388444d-1150-f571-c520-3c8dd369b89c alloc_id=d2c3502a-a03d-3123-0c0f-fee0ec745413 task=redis command=["env"] tty=true
2023-10-06T08:57:56.877+0100 [INFO]  client: task exec session ended with an error: error="rpc error: Permission denied" code=<nil>
2023-10-06T08:57:56.877+0100 [DEBUG] http: alloc exec channel closed with error: error="rpc error: Permission denied"
2023-10-06T08:57:56.878+0100 [ERROR] http: request failed: method=GET path="/v1/client/allocation/d2c3502a-a03d-3123-0c0f-fee0ec745413/exec?command=%5B%22env%22%5D&namespace=system&task=redis&tty=true" error="rpc error: Permission denied" code=500
2023-10-06T08:57:56.878+0100 [DEBUG] http: request complete: method=GET path="/v1/client/allocation/d2c3502a-a03d-3123-0c0f-fee0ec745413/exec?command=%5B%22env%22%5D&namespace=system&task=redis&tty=true" duration=2.298666ms
```
