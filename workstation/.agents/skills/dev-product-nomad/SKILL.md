---
name: dev-product-nomad
description: >-
  Conventions, architecture, and workflows for developing in the HashiCorp Nomad codebase
  (Go workload orchestrator). Use when reading, writing, testing, or reviewing code in a Nomad
  checkout.
---

Nomad is HashiCorp's workload orchestrator, written primarily in Go with an Ember.js UI. Follow
these conventions when working in the codebase. Targets and paths below are verified against the 
`GNUmakefile` and `contributing/README.md`.

## Architecture model

Nomad runs as a single `nomad` binary that behaves as one of two agent roles (a process can be
both in `-dev` mode):

- **Server agents** form a small cluster (typically 3–5). They elect a leader via **Raft** (strong
  consistency for cluster state) and gossip over **Serf** to discover peers and, across regions,
  federate. Servers accept jobs, run the scheduler, and store all cluster state. Server code lives
  in `nomad/`; scheduling logic in `scheduler/`.
- **Client agents** run on every machine that executes workloads. They fingerprint node resources,
  receive allocations from servers, and run tasks through task drivers. Client code lives in
  `client/`; drivers in `drivers/`.

Servers and clients communicate over **RPC** (msgpack via Yamux). Clients heartbeat to the leader;
servers push allocations to clients and receive status updates back.

### Core data model / scheduling lifecycle

These object types (defined in `nomad/structs/`) are the backbone of most code paths:

1. **Job** — the user's desired state (submitted via CLI/API/UI).
2. **Evaluation** — a unit of scheduling work created whenever something changes (job register,
   node failure, alloc failure). Evals are queued in the server's eval broker.
3. **Plan** — the scheduler's proposed set of allocation create/update/stop operations for an eval;
   the leader's plan applier accepts or rejects it against current state.
4. **Allocation** — a mapping of a task group to a specific client node. The target client runs it
   via its allocrunner/taskrunners.

Most server bugs trace to one of: RPC handler, scheduler, plan applier, FSM apply, or state store.
Most client bugs trace to: fingerprinting, allocrunner/taskrunner hooks, or a task driver.

## Repository layout

- `nomad/` — server: RPC handlers (`*_endpoint.go`), raft node, plan applier, eval broker, keyring.
  - `nomad/state/` — in-memory state store (`go-memdb`): schema, tables, `StateStore` methods.
  - `nomad/structs/` — type definitions used in RPC and state.
- `scheduler/` — placement/scheduling logic, called from `nomad/`.
- `client/` — client agent code.
  - `client/allocrunner/` — manages a single allocation and its hooks (identity, CSI, networking).
  - `client/allocrunner/taskrunner/` — manages a single task and its hooks (artifacts, templates,
    Consul mesh, logging); invokes the driver in `drivers/`.
- `command/` — CLI commands (mostly HTTP API clients). `command/agent/` is the HTTP API server
  and config parsing; `command/agent/consul/` is the Consul client.
- `api/` — public Go SDK for the HTTP API. `plugins/` — driver/device/CSI interface definitions.
- `drivers/` — built-in `docker`, `exec`, `raw_exec`, `java`, `qemu` drivers and shared executor.
- `acl/` — ACL policy definitions. `ui/` — web UI. `website/` — docs.

Only `api/` and `plugins/` are meant to be imported by other projects; the root module does not
follow semver.

## Control flow

- Reads: `Client -> HTTP API -> RPC -> StateStore`.
- State changes: `Client -> HTTP API -> RPC -> Raft -> FSM -> StateStore`.

New persisted fields typically need changes across `api/`, `command/agent` HTTP handler,
`nomad/*_endpoint.go` RPC, `nomad/fsm.go` apply path, and `nomad/state` schema. Structs in the
state store are treated as immutable: call `Copy()` before mutating, and extend `Copy()`/`Equal()`
when adding fields.

## Feature checklists

For multi-touch changes, copy the relevant checklist into the PR (found in `contributing/`):
`checklist-jobspec.md`, `checklist-command.md`, `checklist-rpc-endpoint.md`.

## Build, generate, and test

- `make dev` — build a dev binary to `./bin/nomad` (no UI unless `make dev-ui`).
- `make test` — human smoke test (subset; some tests need root). For real work, run targeted
  `go test`, e.g. `go test ./nomad -run TestName -v`, and let CI run the full matrix.
- `make test-nomad` — CI-style unit run via `gotestsum` (retries flakes).
- `make generate-all` — regenerate structs (`go generate`) and protobufs. `make proto` after
  editing any `.proto`. Never hand-edit generated files; commit regenerated output.
- `make cl` — create a changelog entry (see below).

## `make check` — pass this before finishing

`make check` runs `golangci-lint` (root and `api/`) plus these isolation/sync rules that commonly
break CI:

- `command/` must not import `nomad/structs`.
- `api/` and `jobspec2/` must not import internal `nomad/` packages.
- Protobuf output must be regenerated and in sync (run `make proto`).
- HCL/`.nomad`/`.tf` files must be formatted (`make hclfmt`).
- `go.mod`/`go.sum` must be tidy across the root, `api/`, and `tools/` modules (`make tidy`).
- `hclog` call sites are vetted (`hclogvet`).

New source files need license headers; run `make copywriteheaders` if the header check fails.

## Code conventions

- Tests use `github.com/shoenig/test/must`, are table-driven where appropriate, and mark
  parallel-safe tests with `ci.Parallel(t)`. All new functionality needs coverage.
- Use `hclog` for logging; match surrounding error-wrapping and context-propagation patterns.
- Mirror new fields in both `nomad/structs` and `api/` when they must reach API clients, keeping
  `api/` free of internal imports.

## Changelog

- User-facing changes need an entry generated by `make cl` (writes to `.changelog/<PR>.txt`).
- Block types: `release-note:bug`, `release-note:improvement`, `release-note:feature`,
  `release-note:security`, `release-note:breaking-change`, `release-note:deprecation`,
  `release-note:note`. Example:

  ```
  ```release-note:bug
  scheduler: Fixed a bug where ...
  ```
  ```

- Internal-only changes (tests, refactors, CI) do not need an entry.

## AI usage

If asked, follow the repo's `contributing/ai.md` guidelines for AI-assisted contributions.
