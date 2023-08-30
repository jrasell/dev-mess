# Nomad ACL Roles with Duplicated Policies
This is the reproduction for [GH-17201](https://github.com/hashicorp/nomad/issues/17201) which
details erroneous permissions granted when an ACL role contains duplicate ACL policies.

### Assumptions
- Nomad is running with the HTTP API available at `http://127.0.0.1:4646` and ACL's are enabled but
not bootstrapped.

1. Execute the setup script.
```shell
$ bash ./setup.sh
```

2. Generate a Nomad ACL token; once generated export this using `export NOMAD_TOKEN=<SECRET_ID>`.
```shell
$ nomad acl token create -role-name=my-role-sre -role-name=my-role
```

3. Attempt to exec into the running allocation.
```shell
$ nomad alloc exec -namespace=jrasell <ALLOC_ID> /bin/bash
```

This attempt should return an error, which is erroneous as the ACL token has permission to allow
the capability.
```
failed to exec into task: rpc error: Permission denied
```

The Nomad agent logs contain useful log information detailing the permission denied error.
```
2023-08-30T13:58:41.733+0100 [DEBUG] http: request complete: method=GET path=/v1/allocation/cadde080-ac78-590a-d263-f1906fdb898d?namespace=jrasell duration="546.333µs"
2023-08-30T13:58:41.737+0100 [DEBUG] http: request failed: method=GET path=/v1/node/c8211a94-acef-9878-27fa-a2311c9c35c5?namespace=jrasell error="Permission denied" code=403
2023-08-30T13:58:41.737+0100 [DEBUG] http: request complete: method=GET path=/v1/node/c8211a94-acef-9878-27fa-a2311c9c35c5?namespace=jrasell duration=1.153458ms
2023-08-30T13:58:41.739+0100 [ERROR] client.rpc: error performing RPC to server: error="rpc error: Permission denied" rpc=ACL.GetPolicies server=127.0.0.1:4647
2023-08-30T13:58:41.739+0100 [ERROR] client.rpc: error performing RPC to server which is not safe to automatically retry: error="rpc error: Permission denied" rpc=ACL.GetPolicies server=127.0.0.1:4647
2023-08-30T13:58:41.739+0100 [INFO]  client: task exec session starting: exec_id=d3748713-b7c1-5147-c88e-b29969fe4d26 alloc_id=cadde080-ac78-590a-d263-f1906fdb898d task=redis command=["example"] tty=true
2023-08-30T13:58:41.739+0100 [INFO]  client: task exec session ended with an error: error="rpc error: Permission denied" code=<nil>
2023-08-30T13:58:41.739+0100 [DEBUG] http: alloc exec channel closed with error: error="rpc error: Permission denied"
2023-08-30T13:58:41.740+0100 [ERROR] http: request failed: method=GET path="/v1/client/allocation/cadde080-ac78-590a-d263-f1906fdb898d/exec?command=%5B%22example%22%5D&namespace=jrasell&task=redis&tty=true" error="rpc error: Permission denied" code=500
2023-08-30T13:58:41.740+0100 [DEBUG] http: request complete: method=GET path="/v1/client/allocation/cadde080-ac78-590a-d263-f1906fdb898d/exec?command=%5B%22example%22%5D&namespace=jrasell&task=redis&tty=true" duration=2.093625ms
```
