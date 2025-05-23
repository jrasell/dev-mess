locals {
  stack_region  = "eu-west-2"
  stack_name    = "virt"
  stack_owner   = "jrasell"
  ansible_user  = "jrasell"
  ec2_ami_id    = "ami-03628db51da52eeaa"
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

module "ceph_compute" {
  source = "../../shared/terraform/aws-compute"

  ansible_group_name = "ceph"
  component_name     = "ceph"
  ebs_block_devices  = [
    {
      size   = 50
      type   = "gp3"
      device = "/dev/xvdc"
    },
    {
      size   = 50
      type   = "gp3"
      device = "/dev/xvdd"
    }
  ]
  security_group_ids = [module.network.security_group_id]
  ssh_key_name       = module.keys.key_name
  stack_name         = local.stack_name
  subnet_id          = module.network.subnet_id
  user_data          = local.ec2_user_data
}

module "virt_compute" {
  source = "../../shared/terraform/aws-compute"

  ami_id             = "ami-0474244c88b835731"
  ansible_group_name = "virt"
  component_name     = "virt"
  instance_type      = "c5n.metal"
  security_group_ids = [module.network.security_group_id]
  ssh_key_name       = module.keys.key_name
  stack_name         = local.stack_name
  subnet_id          = module.network.subnet_id
  user_data          = local.ec2_user_data
}

output "ceph_ui" {
  value = "Ceph UI: https://${module.ceph_compute.instance_public_ips[0]}:8443"
}

output "ssh_details" {
  value = <<EOH
Ceph instance: ${module.ceph_compute.instance_public_ips[0]}
Virt instance: ${module.virt_compute.instance_public_ips[0]}
EOH
}
