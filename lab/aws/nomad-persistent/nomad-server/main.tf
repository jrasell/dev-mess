data "terraform_remote_state" "base" {
  backend = "local"

  config = {
    path = "../base/terraform.tfstate"
  }
}

locals {
  stack_region    = "eu-west-2"
  stack_component = "nomad-server"
  stack_name      = "eu-nomad-persistent"
  stack_owner     = "jrasell"
  ec2_user_data   = <<EOH
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

  ec2_iam_policy = <<EOH
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "ec2:DescribeInstances",
            "Resource": "*"
        }
    ]
}
EOH
}

provider "aws" {
  region = local.stack_region
}

module "ami" {
  source = "../../../shared/terraform/aws-ami"
}

module "nomad_server" {
  source = "../../../shared/terraform/aws-compute"

  ami_id               = module.ami.ami_id
  ansible_group_name   = "nomad_server"
  ansible_bastion_host = data.terraform_remote_state.base.outputs.bastion_host_ip
  component_name       = local.stack_component
  instance_count       = 3
  instance_iam_policy  = local.ec2_iam_policy
  instance_public_ip   = false
  security_group_ids   = [data.terraform_remote_state.base.outputs.nomad_security_group_id]
  ssh_key_name         = data.terraform_remote_state.base.outputs.ec2_key_name
  stack_name           = local.stack_name
  stack_owner          = local.stack_owner
  subnet_id            = data.terraform_remote_state.base.outputs.vpc_private_subnets[0]
  user_data            = local.ec2_user_data
}

module "nomad_server_0_tls" {
  source = "../../../shared/terraform/tls"

  local_path = "${path.root}/../.tls"

  certificate = {
    name           = "nomad-server-0"
    dns_names      = ["localhost", "nomad_server_0", "server.eu1.nomad"]
    ip_addresses   = ["127.0.0.1", module.nomad_server.instance_private_ips[0]]
    validity_hours = 720
    ca_cert_pem    = file("../.tls/ca.pem")
    ca_cert_key    = file("../.tls/ca-key.pem")
  }
}

module "nomad_server_1_tls" {
  source = "../../../shared/terraform/tls"

  local_path = "${path.root}/../.tls"

  certificate = {
    name           = "nomad-server-1"
    dns_names      = ["localhost", "nomad-server-1", "server.eu1.nomad"]
    ip_addresses   = ["127.0.0.1", module.nomad_server.instance_private_ips[1]]
    validity_hours = 720
    ca_cert_pem    = file("../.tls/ca.pem")
    ca_cert_key    = file("../.tls/ca-key.pem")
  }
}

module "nomad_server_2_tls" {
  source = "../../../shared/terraform/tls"

  local_path = "${path.root}/../.tls"

  certificate = {
    name           = "nomad-server-2"
    dns_names      = ["localhost", "nomad-server-2", "server.eu1.nomad"]
    ip_addresses   = ["127.0.0.1", module.nomad_server.instance_private_ips[2]]
    validity_hours = 720
    ca_cert_pem    = file("../.tls/ca.pem")
    ca_cert_key    = file("../.tls/ca-key.pem")
  }
}

output "details" {
  value = <<EOH
Nomad Server SSH Commands:
%{for ip in module.nomad_server.instance_private_ips~}
  - ssh -J ${data.terraform_remote_state.base.outputs.bastion_host_ip} ${ip}
%{endfor~}

Nomad API Tunnel Commands:
%{for ip in module.nomad_server.instance_private_ips~}
  - ssh -L 4646:${ip}:4646 ${data.terraform_remote_state.base.outputs.bastion_host_ip}
%{endfor~}
EOH
}
