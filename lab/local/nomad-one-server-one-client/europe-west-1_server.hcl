data_dir = "/tmp/nomad-one-server-one-client/server"

log_level            = "DEBUG"
log_include_location = true
enable_debug         = true
region               = "euw1"

telemetry {
  in_memory_collection_interval = "1s"
  in_memory_retention_period    = "10s"
  prometheus_metrics            = true
}

server {
  authoritative_region = "euw1"
  enabled              = true
  bootstrap_expect     = 1
}

acl {
  enabled = true
}
