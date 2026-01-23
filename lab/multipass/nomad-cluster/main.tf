module "nomad_server" {
  source = "../../shared/terraform/multipass-compute"

  ansible_group_name   = "nomad_server"
  instance_count       = 3
  instance_cpus        = 2
  instance_memory      = "4GiB"
  instance_name_prefix = "nomad-server"
  instance_ssh_key     = file("~/.ssh/id_rsa.pub")
}

module "nomad_client" {
  source = "../../shared/terraform/multipass-compute"

  ansible_group_name   = "nomad_client"
  instance_count       = 2
  instance_memory      = "4GiB"
  instance_name_prefix = "nomad-client"
  instance_ssh_key     = file("~/.ssh/id_rsa.pub")
}

module "ansible_provision" {
  source     = "../../shared/terraform/ansible-provision"
  depends_on = [module.nomad_server]

  ansible_inventory_path = abspath("./inventory.yaml")
  ansible_playbook_path  = abspath("./playbook_all.yaml")
}

output "details" {
  value = <<EOH
SSH commands:
  Nomad Servers:
%{for ip in module.nomad_server.instance_ips~}
    - ssh ${ip}
%{endfor~}
  Nomad Client:
%{for ip in module.nomad_client.instance_ips~}
    - ssh ${ip}
%{endfor~}

Rsync commands:
  Nomad Servers:
%{for ip in module.nomad_server.instance_ips~}
    - rsync -r --exclude 'nomad/ui/node_modules/*' /Users/jrasell/Projects/Go/nomad jrasell@${ip}:/home/jrasell/
%{endfor~}
  Nomad Client:
%{for ip in module.nomad_client.instance_ips~}
    - rsync -r --exclude 'nomad/ui/node_modules/*' /Users/jrasell/Projects/Go/nomad jrasell@${ip}:/home/jrasell/
%{endfor~}

Nomad HTTP API Port Forwarding:
%{for ip in module.nomad_server.instance_ips~}
    - ssh -L 4646:${ip}:4646 ${ip}
%{endfor~}
EOH
}
