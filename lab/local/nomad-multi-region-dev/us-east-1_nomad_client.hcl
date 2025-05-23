data_dir   = "/tmp/nomad-multi-region-dev/us-east-1/client-1/"

log_level            = "DEBUG"
log_include_location = true
enable_debug         = true
region               = "us-east-1"
name                 = "client-1"

telemetry {
  publish_allocation_metrics = true
  publish_node_metrics       = true
  prometheus_metrics         = true
}

client {
  enabled = true

  server_join {
    retry_join = ["127.0.0.1:9001"]
  }
}

acl {
  enabled = true
}

ports {
  http = 9100
}
