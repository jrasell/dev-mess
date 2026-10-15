---
name: rust-libs
description: Preferred libraries for Rust projects.
disable-model-invocation: true
---

Edition 2024. Pin dependencies at the latest minor (`"1.1"`, `"0.8"`). Keep
2025. `default-features = false` and list features explicitly when a crate is heavy (e.g. sqlx).

## Libraries

| Concern | Use | Notes |
|---|---|---|
| Async runtime | `tokio` | Enable only needed features: `rt-multi-thread`, `net`, `macros`, `time`, `sync`, `signal`. |
| Task cancellation | `tokio-util` (`CancellationToken`) | Pair with `tokio::select!`. Store the token with its state; do not abort `JoinHandle`s. |
| HTTP server | `axum` 0.8 | Path params use `{id}` syntax. |
| HTTP middleware | `tower`, `tower-http` (`trace`) | Use `route_layer` so `MatchedPath` is available. |
| Rate limiting | `tower_governor` + `governor` | |
| Database | `sqlx` (Postgres, `runtime-tokio`, `tls-rustls`, `migrate`, `macros`, `chrono`) | Migrations in `./migrations`, run at startup via `sqlx::migrate!`. |
| Serialization | `serde` (`derive`) | |
| Config files | `toml` + `serde` | Every field has a default. Use `#[serde(deny_unknown_fields, default)]`. |
| Time | `chrono` (`serde` feature) | |
| Logging | `tracing` + `tracing-subscriber` (`env-filter`, `json`) | |
| Metrics | `metrics` + `metrics-exporter-prometheus` + `metrics-process` | |
| CLI parsing | `clap` 4 (`derive`, `env`, `wrap_help`) + `clap_complete` | |
