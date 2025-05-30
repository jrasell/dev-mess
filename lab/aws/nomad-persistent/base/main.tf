locals {
  stack_region  = "eu-west-2"
  stack_owner   = "jrasell"
  stack_name    = "eu-nomad-persistent"
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

module "ca" {
  source = "../../../shared/terraform/tls"

  local_path    = "${path.root}/../.tls"
  ca_create     = true
  ca_upload_aws = {
    bucket = "jrasell"
    key    = "eu1/certs"
  }
}

module "keys" {
  source  = "mitchellh/dynamic-keys/aws"
  version = "v2.0.0"

  name = local.stack_name
  path = "${path.root}/../.keys"
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = local.stack_name
  cidr = "10.10.0.0/16"

  azs             = ["eu-west-2a", "eu-west-2b", "eu-west-2c"]
  private_subnets = ["10.10.1.0/24", "10.10.2.0/24", "10.10.3.0/24"]
  public_subnets  = ["10.10.4.0/24", "10.10.5.0/24", "10.10.6.0/24"]

  enable_nat_gateway = true

  tags = {
    stack_name  = local.stack_name
    stack_owner = local.stack_owner
  }
}

module "ami" {
  source = "../../../shared/terraform/aws-ami"
}

module "bastion" {
  source = "../../../shared/terraform/aws-compute"

  ami_id              = module.ami.ami_id
  ansible_group_name  = "bastion"
  component_name      = "eu-nomad-bastion"
  instance_count      = 1
  security_group_ids  = [aws_security_group.bastion.id]
  ssh_key_name        = module.keys.key_name
  stack_name          = local.stack_name
  stack_owner         = local.stack_owner
  subnet_id           = module.vpc.public_subnets[1]
  user_data           = local.ec2_user_data
}

output "ec2_key_name" {
  value = module.keys.key_name
}

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "vpc_private_subnets" {
  value = module.vpc.private_subnets
}

output "nomad_security_group_id" {
  value = aws_security_group.nomad.id
}

output "bastion_host_ip" {
  value = module.bastion.instance_public_ips[0]
}
