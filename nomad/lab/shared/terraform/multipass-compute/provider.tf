terraform {
  required_providers {
    multipass = {
      source  = "larstobi/multipass"
      version = "~> 1.4.2"
    }
    ansible = {
      version = "1.3.0"
      source  = "ansible/ansible"
    }
  }
}
