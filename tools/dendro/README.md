# dendro

Compare Go dependency versions across Git branches using a scratch clone. The original repository is
never modified; dendro works from an isolated `git clone --no-checkout`.

## Configuration file

All options can be provided in a TOML file and passed with `--config`. Flags override TOML values.

```toml
[source]
repository    = "git@github.com:org/repo.git"
branches      = ["main", "release/1.10.x"]
go_mods       = ["go.mod", "jobspec2/go.mod"]
web_url       = "https://github.com/org/repo"

[check]
go          = ["golang.org/x/mod", "github.com/hashicorp/go-hclog"]
direct_only = false

[diff]
go          = ["golang.org/x/mod"]
direct_only = false

[output]
format = "table"
file   = "results.csv"

[log]
level   = "info"
console = false
```

### `[source]` options

| Key | Required | Description |
|---|---|---|
| `repository` | **yes** | Git repository — remote URL (`git@…` or `https://…`) or a local path. A relative local path is resolved relative to the config file. |
| `branches` | **yes** | List of branch names to inspect. |
| `go_mods` | no | Paths to `go.mod` files within the repository, relative to the repository root. Defaults to `["go.mod"]`. Each module is identified in output as `go@root`, `go@<dir>`, etc. |
| `web_url` | no | HTTPS base URL of the repository (e.g. `https://github.com/org/repo`). Used to generate clickable evidence permalink URLs in output. Inferred automatically from `git remote` for GitHub/GitLab/Bitbucket remotes. |

### `[check]` and `[diff]` options

These sections are mode-specific. The `[check]` section is read when running `check`; `[diff]` when running `diff`.

| Key | Required | Description |
|---|---|---|
| `go` | **yes** (check only) | List of Go module paths to inspect (e.g. `["golang.org/x/mod"]`). In `diff` mode, omitting this key diffs all modules found across branches. |
| `direct_only` | no | When `true`, only direct dependencies (non-`// indirect`) are considered. Default: `false`. |

### `[output]` options

| Key | Default | Description |
|---|---|---|
| `format` | `table` | Output format: `table`, `csv`, or `json`. |
| `file` | _(stdout)_ | Write results to this file path instead of stdout. A relative path resolves from the current working directory. When a file is set, results are written atomically (via a temp file + rename). |

### `[log]` options

| Key | Default | Description |
|---|---|---|
| `level` | `info` | Log level: `debug`, `info`, `warn`, or `error`. |
| `console` | `false` | When `true`, log lines are also printed to stderr. Logs always append to `dendro/dendro.log` in the user cache directory (e.g. `~/Library/Caches/dendro/dendro.log` on macOS). |

## CLI flags

All flags correspond to the TOML options above and override them when set. The `--config` flag is
the only flag with no TOML equivalent.

| Flag | Alias | Description |
|---|---|---|
| `--config` | | Path to the TOML configuration file. |
| `--repo` | | Overrides `[source].repository`. |
| `--ref` | `--branch` | Overrides `[source].branches`. Repeatable. |
| `--web-url` | | Overrides `[source].web_url`. |
| `--go-mod` | | Overrides `[source].go_mods`. Repeatable. |
| `--go-dep` | | Overrides `[check].go` / `[diff].go`. Repeatable. |
| `--direct` | | Overrides `direct_only`. |
| `--output-format` | `--format` | Overrides `[output].format`. |
| `--output-file` | `--output` | Overrides `[output].file`. |
| `--log-level` | | Overrides `[log].level`. |
| `--log-console` | | Overrides `[log].console`. |

## Output

Results are sorted by ecosystem label, then branch (check) or dependency name (diff). Each Go module
is labelled `go@root` for a root `go.mod`, or `go@<dir>` for a nested one (e.g. `go@jobspec2`).

**JSON output** (`--output-format json`) produces an object with a `mode` string and a `results` array:

- `check` results: each entry has `branch`, `ecosystem`, `dependency`, `version` (nullable), and `evidence_url` (optional).
- `diff` results: each entry has `ecosystem`, `dependency`, and a `branches` object mapping branch name to `{version, evidence_url}`.
