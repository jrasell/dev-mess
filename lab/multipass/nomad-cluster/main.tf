variable "consul_address" { default = "" }
variable "vault_address" { default = "" }

module "ca" {
  source = "../../shared/terraform/tls"

  local_path = "${path.root}/.tls"
  ca_create  = true
}

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
  depends_on = [module.ca, module.nomad_server, module.nomad_client]

  ansible_inventory_path = abspath("./inventory.yaml")
  ansible_playbook_path  = abspath("./playbook_all.yaml")
  ansible_extra_vars = compact([
    var.consul_address != "" ? "consul_address=${var.consul_address}" : "",
    var.vault_address != "" ? "vault_address=${var.vault_address}" : "",
  ])
}

output "msg" {
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

Nomad HTTP API:
%{for ip in module.nomad_server.instance_ips~}
    - https://${ip}:4646
%{endfor~}
EOH
}

output "nomad_ca_cert_pem" {
  value = module.ca.ca_cert_pem
}

output "nomad_server_addresses" {
  value = module.nomad_server.instance_ips
}
