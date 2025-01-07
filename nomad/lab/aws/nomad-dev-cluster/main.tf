locals {
  ec2_ami_id    = "ami-0474244c88b835731"
  stack_region  = "eu-west-2"
  stack_name    = "nomad-cluster"
  stack_owner   = "jrasell"
  ec2_user_data = <<EOH
#cloud-config
---
users:
  - default
  - name: jrasell
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    ssh_authorized_keys:
      - ssh-rsa
        AAAAB3NzaC1yc2EAAAADAQABAAABgQCh9U/cDg3ZUZMS57hfayRVWol8bI046+sbXZyRLv7eXHyg42j7H3utJ5vQE+z1Crkb4W2gXQE5cMrtVe5ee3NBP9I9cxljYZ3WMXRwInp5GmRKGBIMD0zLfoJJz+hnyRQl67mMi0s5x2CHfDbDq/N028W2XQLWydaulKg4y6GVIRf/a1Fn8YaBd6OlmPU9flpvBShSV1JU0++fk8mK2u9cJ4vue/1PBVbu55YZynk5EubhLsqpKWqDHQUsg4fE0IAyszs8FuA3NYFU0yUMAOx9Wt5oql05MSNNJfYmqZqmysdxJjfTEOdURN/3hWZnd4fbbfJq06Nh+JYrEndEIRB9SoWaD/EsSN65oTL/kHb9ofvj37pPKyzMwG82gQ8/mZI476ZOS59I9DfRW+AWQemuo4NNQlKkBIejmqz88AUM+XN4sdZVBLs1Lz3uuHmXV5bh1pIwwr7Mo9mJru3o69/cpKSTotvjgBUyEjNTGxXb12w1iiHjI8EH3q+Yn3efeu8=
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

module "network" {
  source     = "../../shared/terraform/aws-network"
  stack_name = local.stack_name
}

module "nomad_server" {
  source = "../../shared/terraform/aws-compute"

  ami_id             = local.ec2_ami_id
  ansible_group_name = "nomad_server"
  component_name     = "nomad_server"
  security_group_ids = [module.network.security_group_id]
  ssh_key_name       = module.keys.key_name
  stack_name         = local.stack_name
  stack_owner        = local.stack_owner
  subnet_id          = module.network.subnet_id
  user_data          = local.ec2_user_data
}

module "nomad_client" {
  source = "../../shared/terraform/aws-compute"

  ami_id             = local.ec2_ami_id
  ansible_group_name = "nomad_client"
  component_name     = "nomad_client"
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
  Nomad Server: ssh ${module.nomad_server.instance_public_ips[0]}
  Nomad Client: ssh ${module.nomad_client.instance_public_ips[0]}

Rsync commands:
  Nomad Server: rsync -r --exclude 'nomad/ui/node_modules/*' /Users/jrasell/Projects/Go/nomad jrasell@${module.nomad_server.instance_public_ips[0]}:/home/jrasell/
  Nomad Client: rsync -r --exclude 'nomad/ui/node_modules/*' /Users/jrasell/Projects/Go/nomad jrasell@${module.nomad_client.instance_public_ips[0]}:/home/jrasell/
EOH
}
