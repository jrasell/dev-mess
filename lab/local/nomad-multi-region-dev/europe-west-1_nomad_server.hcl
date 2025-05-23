data_dir   = "/tmp/nomad-multi-region-dev/europe-west-1/server-1/"

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

server {
  authoritative_region = "europe-west-1"
  enabled              = true
  bootstrap_expect     = 1
}

acl {
  enabled = true
}
