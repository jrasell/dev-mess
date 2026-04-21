variable "nomad_addresses" { type = list(string) }
variable "nomad_cert_pem" {}
variable "vault_address" { default = "" }
variable "vault_token" { default = null }

provider "vault" {
  address = "http://${var.vault_address}:8200"
  token   = var.vault_token
}

module "vault_nomad_wi" {
  source = "../../../shared/terraform/hashicorp-vault-nomad-wi"

  nomad_address     = "https://${var.nomad_addresses[0]}:4646"
  nomad_jwks_ca_pem = var.nomad_cert_pem
  vault_kv_mount    = "nomad-lcy1"

  providers = {
    vault = vault
  }
}
