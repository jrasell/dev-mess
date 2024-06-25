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

locals {
  lab_name          = "jrasell-remote-workstation"
  ec2_ami_name      = "ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-20240606"
  ec2_instance_type = "t3.large"
}

module "keys" {
  source  = "mitchellh/dynamic-keys/aws"
  version = "v2.0.0"

  name = local.lab_name
  path = "${path.root}/keys"
}

data "aws_ami" "ubuntu" {
  filter {
    name   = "name"
    values = [local.ec2_ami_name]
  }

  most_recent = true
  owners      = ["099720109477"] # Canonical
}

provider "aws" {
  region = "eu-west-2"
}

resource "aws_instance" "workstation" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = local.ec2_instance_type
  subnet_id                   = aws_subnet.nomad_test_subnet.id
  vpc_security_group_ids      = [aws_security_group.allow_all.id]
  key_name                    = module.keys.key_name
  associate_public_ip_address = true

  user_data                   = <<EOH
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
  user_data_replace_on_change = true

  root_block_device {
    volume_size = 100
    volume_type = "gp3"
  }

  tags = {
    Name  = local.lab_name
    Owner = "jrasell@hashicorp.com"
  }
}

data "http" "myip" {
  url = "http://ipv4.icanhazip.com"
}

resource "aws_vpc" "nomad_test_vpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = local.lab_name
  }
}

resource "aws_internet_gateway" "nomad_test_igw" {
  vpc_id = aws_vpc.nomad_test_vpc.id

  tags = {
    Name = local.lab_name
  }
}

resource "aws_default_route_table" "nomad_test_route_table" {
  default_route_table_id = aws_vpc.nomad_test_vpc.default_route_table_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.nomad_test_igw.id
  }

  tags = {
    Name = local.lab_name
  }
}

resource "aws_subnet" "nomad_test_subnet" {
  vpc_id     = aws_vpc.nomad_test_vpc.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = local.lab_name
  }
}

resource "aws_security_group" "allow_all" {
  name   = "allow_all"
  vpc_id = aws_vpc.nomad_test_vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.1.0/24", "${chomp(data.http.myip.response_body)}/32"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "ansible_group" "workstation" {
  name = "workstation"

  variables = {
    ansible_user = "jrasell"
  }
}

resource "ansible_host" "workstation" {
  name   = "workstation-0"
  groups = [ansible_group.workstation.name]

  variables = {
    ansible_host = aws_instance.workstation.public_ip
  }
}

output "instance_public_ip" {
  value = aws_instance.workstation.public_ip
}
