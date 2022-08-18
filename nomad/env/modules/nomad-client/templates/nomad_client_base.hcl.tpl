data_dir   = "/opt/nomad"
region     = "${region}"

server {
  enabled = false
}

client {
  enabled           = true
  network_interface = "eth1"

  server_join {
    retry_join = ${server_ips}
  }
}

advertise {
  http = "{{ GetInterfaceIP \"eth1\" }}"
  rpc  = "{{ GetInterfaceIP \"eth1\" }}"
  serf = "{{ GetInterfaceIP \"eth1\" }}"
}

telemetry {
  publish_allocation_metrics = true
  publish_node_metrics       = true
  prometheus_metrics         = true
}

plugin "raw_exec" {
  config {
    enabled = true
  }
}

plugin "docker" {
  config {
    allow_privileged = true
  }
}

acl {
  enabled = true
}

log_level = "DEBUG"
log_json  = true
log_file  = "/var/log/nomad.log"
