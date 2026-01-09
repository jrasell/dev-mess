module "nomad" {
  source = "../../shared/terraform/multipass-compute"

  ansible_group_name   = "nomad"
  instance_count       = 1
  instance_cpus        = 4
  instance_memory      = "4GiB"
  instance_name_prefix = "nomad"
  instance_ssh_key     = file("~/.ssh/id_rsa.pub")
}

module "ansible_provision" {
  source     = "../../shared/terraform/ansible-provision"
  depends_on = [module.nomad]

  ansible_inventory_path = abspath("./inventory.yaml")
  ansible_playbook_path  = abspath("./playbook_all.yaml")
}

output "details" {
  value = <<EOH
SSH: ssh ${module.nomad.instance_ips[0]}
Nomad HTTP API Port Forwarding: ssh -L 4646:${module.nomad.instance_ips[0]}:4646 ${module.nomad.instance_ips[0]}
EOH
}
