module "victoria_metrics_server" {
  source = "../../shared/terraform/multipass-compute"

  ansible_group_name   = "victoria_metrics"
  instance_count       = 1
  instance_cpus        = 1
  instance_memory      = "1GiB"
  instance_name_prefix = "victoria-metrics-server"
  instance_ssh_key     = file("~/.ssh/id_rsa.pub")
}

module "ansible_provision" {
  source     = "../../shared/terraform/ansible-provision"
  depends_on = [module.victoria_metrics_server]

  ansible_inventory_path = abspath("./inventory.yaml")
  ansible_playbook_path  = abspath("./playbook_all.yaml")
}

output "msg" {
  value = <<EOH
SSH:              ssh ${module.victoria_metrics_server.instance_ips[0]}
Metrics UI:       http://${module.victoria_metrics_server.instance_ips[0]}:8428
Logs UI:          http://${module.victoria_metrics_server.instance_ips[0]}:9428
Tracing UI:       http://${module.victoria_metrics_server.instance_ips[0]}:10428
EOH
}

output "victoria_metrics_server_address" {
  value = module.victoria_metrics_server.instance_ips[0]
}
