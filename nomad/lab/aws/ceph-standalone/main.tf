terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
    ansible = {
      version = "1.3.0"
      source  = "ansible/ansible"
    }
  }
  required_version = ">= 1.2.0"
}

provider "aws" {
  region = local.lab_region
}

# Locals are the useful variables within this lab which can be easily changed
# if desired.
locals {
  lab_region        = "eu-west-2"
  lab_name          = "ceph-standalone"
  lab_owner         = "jrasell"
  lab_ansible_user  = "jrasell"
  ec2_ami_id        = "ami-03628db51da52eeaa"
  ec2_instance_type = "m5.xlarge"
  ec2_user_data     = <<EOH
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

# Generate an SSH key pair and import it into AWS.
module "keys" {
  source  = "mitchellh/dynamic-keys/aws"
  version = "v2.0.0"

  name = local.lab_name
  path = "${path.root}/keys"
}

resource "aws_instance" "ceph" {
  ami                         = local.ec2_ami_id
  instance_type               = local.ec2_instance_type
  subnet_id                   = aws_subnet.nomad_test_subnet.id
  vpc_security_group_ids      = [aws_security_group.allow_all.id]
  key_name                    = module.keys.key_name
  associate_public_ip_address = true
  user_data                   = local.ec2_user_data
  user_data_replace_on_change = true

  root_block_device {
    volume_size = 100
    volume_type = "gp3"
  }

  # Add two EBS block devices which can be assigned to Ceph for management.
  ebs_block_device {
    volume_size = 50
    volume_type = "gp3"
    device_name = "/dev/xvdc"
  }
  ebs_block_device {
    volume_size = 50
    volume_type = "gp3"
    device_name = "/dev/xvdd"
  }

  tags = {
    Name  = local.lab_name
    Owner = local.lab_owner
  }
}

data "http" "myip" {
  url = "http://ipv4.icanhazip.com"
}

resource "aws_vpc" "nomad_test_vpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name  = local.lab_name
    Owner = local.lab_owner
  }
}

resource "aws_internet_gateway" "nomad_test_igw" {
  vpc_id = aws_vpc.nomad_test_vpc.id

  tags = {
    Name  = local.lab_name
    Owner = local.lab_owner
  }
}

resource "aws_default_route_table" "nomad_test_route_table" {
  default_route_table_id = aws_vpc.nomad_test_vpc.default_route_table_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.nomad_test_igw.id
  }

  tags = {
    Name  = local.lab_name
    Owner = local.lab_owner
  }
}

resource "aws_subnet" "nomad_test_subnet" {
  vpc_id     = aws_vpc.nomad_test_vpc.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name  = local.lab_name
    Owner = local.lab_owner
  }
}

resource "aws_security_group" "allow_all" {
  name   = "allow_all"
  vpc_id = aws_vpc.nomad_test_vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [
      aws_vpc.nomad_test_vpc.cidr_block,
      "${chomp(data.http.myip.response_body)}/32",
    ]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "ansible_group" "ceph" {
  name = "ceph"

  variables = {
    ansible_user = local.lab_ansible_user
  }
}

resource "ansible_host" "ceph" {
  name   = "ceph-0"
  groups = [ansible_group.ceph.name]

  variables = {
    ansible_host = aws_instance.ceph.public_ip
  }
}

output "instance_public_ip" {
  value = aws_instance.ceph.public_ip
}

output "message" {
  value = "Once bootstrapped, the Ceph UI will be at: https://${aws_instance.ceph.public_ip}:8443"
}
