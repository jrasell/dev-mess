data_dir   = "/tmp/nomad-multi-region-dev/asia-south-1/client-1/"

log_level            = "DEBUG"
log_include_location = true
enable_debug         = true
region               = "asia-south-1"
name                 = "server-1"

telemetry {
  publish_allocation_metrics = true
  publish_node_metrics       = true
  prometheus_metrics         = true
}

client {
  enabled = true

  server_join {
    retry_join = ["127.0.0.1:10001"]
  }
}

acl {
  enabled = true
}

ports {
  http = 10100
}
