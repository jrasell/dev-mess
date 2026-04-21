variable "nomad_address" {
  description = "The HTTP API address of the Nomad server."
  type        = string
  default     = "http://localhost:4646"
}

variable "nomad_jwks_ca_pem" {
  description = "The PEM-encoded CA certificate for the Nomad server when running TLS."
  type        = string
  default     = ""
}

variable "vault_kv_mount" {
  description = "The name of the Vault KV mount to use for storing Nomad secrets."
  type        = string
  default     = "nomad"
}
