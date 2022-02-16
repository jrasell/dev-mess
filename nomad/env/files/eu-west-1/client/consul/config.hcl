data_dir   = "/opt/consul"
datacenter = "eu-west-1"

enable_local_script_checks = true
server                     = false
advertise_addr             = "{{ GetInterfaceIP \"eth1\" }}"
bind_addr                  = "0.0.0.0"
client_addr                = "0.0.0.0"

retry_join = [
  "192.168.60.10"
]

ports {
  http  = 8500
  grpc  = 8502
}

service {
  name = "consul-client"
}
