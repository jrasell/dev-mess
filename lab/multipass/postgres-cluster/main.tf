module "postgres" {
  source = "../../shared/terraform/multipass-compute"

  ansible_group_name   = "postgres"
  instance_count       = 3
  instance_cpus        = 2
  instance_memory      = "4GiB"
  instance_name_prefix = "postgres"
  instance_ssh_key     = file("~/.ssh/id_rsa.pub")
}

module "ansible_provision" {
  source     = "../../shared/terraform/ansible-provision"
  depends_on = [module.postgres]

  ansible_inventory_path = abspath("./inventory.yaml")
  ansible_playbook_path  = abspath("./playbook_all.yaml")
}

output "msg" {
  value = <<EOH
SSH commands:
%{for ip in module.postgres.instance_ips~}
    - ssh ${ip}
%{endfor~}

Patroni API:
%{for ip in module.postgres.instance_ips~}
  - curl http://${ip}:8008
%{endfor~}
EOH
}
