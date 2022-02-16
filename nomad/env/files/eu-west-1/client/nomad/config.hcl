data_dir   = "/opt/nomad"
region     = "eu-west-1"

server {
  enabled = false
}

client {
  enabled           = true
  network_interface = "eth1"

  server_join {
    retry_join = [
      "192.168.60.10"
    ]
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
  enabled = false
}

log_level = "DEBUG"
log_json  = true
log_file  = "/var/log/nomad.log"
