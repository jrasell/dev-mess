terraform {
  required_version = ">= 1.3"
  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = ">= 3.20.0"
    }
  }
}
