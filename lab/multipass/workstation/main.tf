module "workstation" {
  source             = "../../shared/terraform/multipass-compute"
  instance_image     = "trixie"
  instance_ssh_key   = file("~/.ssh/id_rsa.pub")
  ansible_group_name = "workstation"
}

module "ansible_provision" {
  source     = "../../shared/terraform/ansible-provision"
  depends_on = [module.workstation]

  ansible_inventory_path = abspath("./inventory.yaml")
  ansible_playbook_path  = abspath("./playbook_workstation.yaml")
}

output "details" {
  value = <<EOH
SSH commands:
  Workstation: ssh ${module.workstation.instance_ips[0]}
EOH
}
