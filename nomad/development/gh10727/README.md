# Duplicate Allocation Indexes
This is a reproduction for [GH-10727](https://github.com/hashicorp/nomad/issues/10727) which
details duplicated allocation indexes within the same job version.

### Assumptions
- Nomad is running with the HTTP API available at `http://127.0.0.1:4646`; this can be in dev mode
  and does not require ACLs
- Docker is running locally and the Nomad agent can fingerprint this
- JQ installed and available locally

1. Submit the job to Nomad job without setting any variables:
```shell
$ nomad job run gh10727.nomad.hcl
```

2. Trigger a job deployment by submitting a modified job using HCL variables:
```shell
$ nomad job run -var='image=redis:7' -var='count=4' gh10727.nomad.hcl
```

3. View the current running allocations, their name and job version:
```shell
$ nomad operator api /v1/job/gh10727/allocations |jq -r '.[] | select(.ClientStatus=="running") | [.ID,.Name,.JobVersion] '
```

The query should return output similar to that seen below. Importantly, we can see two allocations
whose name is `gh10727.cache[0]` which belong to the same job version.
```js
[
  "3b6ec63b-76d6-1d96-21a2-4669c8ce4083",
  "gh10727.cache[0]",
  1
]
[
  "46ee6397-bf71-231a-8d86-9cda3a7fde35",
  "gh10727.cache[1]",
  1
]
[
  "5b970969-caed-3e62-2486-8d593d3da077",
  "gh10727.cache[0]",
  1
]
[
  "6ded70e3-6824-332a-f0f9-fa397c1cd3e3",
  "gh10727.cache[2]",
  1
]
```
