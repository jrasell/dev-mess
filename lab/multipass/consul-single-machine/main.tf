module "consul_server" {
  source = "../../shared/terraform/multipass-compute"

  ansible_group_name   = "consul_server"
  instance_count       = 1
  instance_cpus        = 2
  instance_memory      = "2GiB"
  instance_name_prefix = "consul-server"
  instance_ssh_key     = file("~/.ssh/id_rsa.pub")
}

module "ansible_provision" {
  source     = "../../shared/terraform/ansible-provision"
  depends_on = [module.consul_server]

  ansible_inventory_path = abspath("./inventory.yaml")
  ansible_playbook_path  = abspath("./playbook_all.yaml")
}

output "msg" {
  value = <<EOH
SSH:        ssh ${module.consul_server.instance_ips[0]}
Consul UI:  http://${module.consul_server.instance_ips[0]}:8500
EOH
}

output "consul_server_address" {
  value = module.consul_server.instance_ips[0]
}
