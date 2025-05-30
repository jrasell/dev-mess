data "terraform_remote_state" "base" {
  backend = "local"

  config = {
    path = "../base/terraform.tfstate"
  }
}

locals {
  stack_region    = "eu-west-2"
  stack_name      = "eu-nomad-persistent"
  stack_owner     = "jrasell"
  stack_component = "eu-nomad-client-mon"
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

runcmd:
  - [apt-get, update]
  - [apt-get, install, -y, ansible]
  - [snap, install, aws-cli, --classic]
  - [git, clone, -b, persistent-test, https://github.com/jrasell/dev-mess.git, /opt/provision]
  - [mkdir, /opt/provision/lab/aws/nomad-persistent/.tls]
  - [aws, s3api, get-object, --bucket=jrasell, --key=eu1/certs/ca.pem, /opt/provision/lab/aws/nomad-persistent/.tls/ca.pem]
  - [aws, s3api, get-object, --bucket=jrasell, --key=eu1/certs/ca-key.pem, /opt/provision/lab/aws/nomad-persistent/.tls/ca-key.pem]
  - [/tmp/provision.sh]

write_files:
  - content: |
      #!/usr/bin/env bash
      
      pushd /opt/provision/lab/aws/nomad-persistent/nomad-client-mon
      ansible-galaxy install -r requirements.yaml
      ansible-playbook playbook_nomad_client.yaml
      popd
      rm -rf /opt/provision

    path: /tmp/provision.sh
    permissions: '0755'
EOH

  ec2_iam_policy   = <<EOH
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "ec2:DescribeInstances",
            "Resource": "*"
        },
        {
         "Effect": "Allow",
         "Action": [
            "s3:ListBucket",
            "s3:GetObject",
            "s3:GetObjectVersion"
         ],
         "Resource": "arn:aws:s3:::jrasell/eu1/certs/*"
         },
        {
         "Effect": "Allow",
         "Action": "s3:ListBucket",
         "Resource": "arn:aws:s3:::jrasell"
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

module "nomad_client_mon" {
  source = "../../../shared/terraform/aws-autoscaling"

  instance_iam_policy = local.ec2_iam_policy
  instance_ami_id     = module.ami.ami_id
  instance_key_name   = data.terraform_remote_state.base.outputs.ec2_key_name
  instance_security_group_ids = [data.terraform_remote_state.base.outputs.nomad_security_group_id]
  instance_type       = "m4.xlarge"
  instance_user_data  = local.ec2_user_data
  stack_component     = local.stack_component
  stack_name          = local.stack_name
  vpc_id              = data.terraform_remote_state.base.outputs.vpc_id
  vpc_subnet_ids      = data.terraform_remote_state.base.outputs.vpc_private_subnets
}
