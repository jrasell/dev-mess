terraform {
  required_providers {
    ansible = {
      version = "1.3.0"
      source  = "ansible/ansible"
    }
    external = {
      source  = "hashicorp/external"
      version = "~> 2.4.2"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.9.1"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.9.1"
    }
  }
}
