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
