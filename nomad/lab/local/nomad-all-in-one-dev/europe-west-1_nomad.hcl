data_dir   = "/tmp/nomad-all-in-one-dev/"

log_level            = "DEBUG"
log_include_location = true
enable_debug         = true
region               = "europe-west-1"
name                 = "server-1"

telemetry {
  publish_allocation_metrics = true
  publish_node_metrics       = true
  prometheus_metrics         = true
}

client {
  enabled = true

  server_join {
    retry_join = ["127.0.0.1:4647"]
  }
}

server {
  authoritative_region = "europe-west-1"
  enabled              = true
  bootstrap_expect     = 1

  job_gc_interval  = "5m"
  job_gc_threshold = "5m"
}

acl {
  enabled = true
}
