data_dir   = "/tmp/nomad-multi-region-dev/asia-south-1/server-1/"

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

server {
  authoritative_region = "europe-west-1"
  enabled              = true
  bootstrap_expect     = 1
}

acl {
  enabled           = true
  replication_token = "a9f9658b-49d3-697c-4469-bae37352e165"
}

ports {
  http = 10000
  rpc  = 10001
  serf = 10002
}
