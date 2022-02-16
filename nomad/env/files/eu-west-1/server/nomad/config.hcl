data_dir = "/opt/nomad"
region   = "eu-west-1"

server {
  enabled          = true
  bootstrap_expect = 1

  server_join {
    retry_join = [
      "192.168.60.10"
    ]
  }
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
  enabled = false
}

log_level = "DEBUG"
log_json  = true
log_file  = "/var/log/nomad.log"
