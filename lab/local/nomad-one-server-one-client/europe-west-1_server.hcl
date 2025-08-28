data_dir = "/tmp/nomad-one-server-one-client/server"

log_level            = "DEBUG"
log_include_location = true
enable_debug         = true
region               = "europe-west-1"

telemetry {
  in_memory_collection_interval = "1s"
  in_memory_retention_period    = "10s"
  prometheus_metrics            = true
}

server {
  authoritative_region = "europe-west-1"
  enabled              = true
  bootstrap_expect     = 1
}
