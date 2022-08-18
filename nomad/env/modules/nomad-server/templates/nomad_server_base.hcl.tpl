data_dir = "/opt/nomad"
region   = "${region}"

server {
  enabled              = true
  bootstrap_expect     = 1
  authoritative_region = "${authoritative_region}"
}

client {
  enabled = false
}

telemetry {
  publish_allocation_metrics = true
  publish_node_metrics       = true
  prometheus_metrics         = true
}

advertise {
  http = "{{ GetInterfaceIP \"eth1\" }}"
  rpc  = "{{ GetInterfaceIP \"eth1\" }}"
  serf = "{{ GetInterfaceIP \"eth1\" }}"
}

acl {
  enabled = true
}

log_level = "DEBUG"
log_json  = true
log_file  = "/var/log/nomad.log"
