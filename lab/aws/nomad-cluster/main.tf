locals {
  stack_region  = "us-east-2"
  stack_name    = "nomad-cluster"
  stack_owner   = "aimeeu"
  ec2_user_data = <<EOH
#cloud-config
---
users:
  - default
  - name: ubuntu
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    ssh_authorized_keys:
      - ssh-rsa ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII1PfYtWT3bEqNQ4DTVu9qTb2zK/ZmWM9Qty/Gxtt0BL ubuntu
EOH
}

provider "aws" {
  region = local.stack_region
}

module "keys" {
  source  = "mitchellh/dynamic-keys/aws"
  version = "v2.0.0"

  name = local.stack_name
  path = "${path.root}/keys"
}

module "ami" {
  source = "../../shared/terraform/aws-ami"
}

module "network" {
  source     = "../../shared/terraform/aws-network"
  stack_name = local.stack_name
}

module "nomad_server" {
  source = "../../shared/terraform/aws-compute"

  ami_id             = module.ami.ami_id
  ansible_group_name = "nomad_server"
  component_name     = "nomad-server"
  instance_count     = 3
  security_group_ids = [module.network.security_group_id]
  ssh_key_name       = module.keys.key_name
  stack_name         = local.stack_name
  stack_owner        = local.stack_owner
  subnet_id          = module.network.subnet_id
  user_data          = local.ec2_user_data
}

module "nomad_client" {
  source = "../../shared/terraform/aws-compute"

  ami_id             = module.ami.ami_id
  ansible_group_name = "nomad_client"
  component_name     = "nomad-client"
  instance_count     = 2
  security_group_ids = [module.network.security_group_id]
  ssh_key_name       = module.keys.key_name
  stack_name         = local.stack_name
  stack_owner        = local.stack_owner
  subnet_id          = module.network.subnet_id
  user_data          = local.ec2_user_data
}

module "ansible_provision" {
  source     = "../../shared/terraform/ansible-provision"
  depends_on = [module.nomad_server, module.nomad_client]

  ansible_inventory_path = abspath("./inventory.yaml")
  ansible_playbook_path  = abspath("./playbook_all.yaml")
}

output "details" {
  value = <<EOH
SSH commands:
  Nomad Servers:
%{for ip in module.nomad_server.instance_public_ips~}
    - ssh ${ip}
%{endfor~}
  Nomad Client:
%{for ip in module.nomad_client.instance_public_ips~}
    - ssh ${ip}
%{endfor~}

Rsync commands:
  Nomad Servers:
%{for ip in module.nomad_server.instance_public_ips~}
    - rsync -r --exclude 'nomad/ui/node_modules/*' /Users/aimeeu/Dev/github/hashicorp/nomad ubuntu@${ip}:/home/ubuntu/
%{endfor~}
  Nomad Client:
%{for ip in module.nomad_client.instance_public_ips~}
    - rsync -r --exclude 'nomad/ui/node_modules/*' /Users/aimeeu/Projects/Go/nomad ubuntu@${ip}:/home/ubuntu/
%{endfor~}
EOH
}
