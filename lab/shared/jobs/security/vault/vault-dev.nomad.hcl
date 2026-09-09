variable "id" {
  type        = string
  description = "The name of the job"
  default     = "vault-dev"
}

variable "node_pool" {
  type        = string
  default     = "default"
  description = "The node pool to target for this job"
}

variable "namespace" {
  description = "The Nomad namespace to deploy to"
  type        = string
  default     = "default"
}

variable "network_mode" {
  description = "The network mode to use"
  type        = string
  default     = "bridge"
}

variable "vault_root_token" {
  description = "The development root token for Vault"
  type        = string
  default     = "f13db0bb-bf40-518e-b157-5b28c0b2e56a"
}

job "vault-dev" {
  id        = var.id
  name      = var.id
  namespace = var.namespace
  node_pool = var.node_pool

  group "vault" {
    shutdown_delay = "10s"

    network {
      mode = var.network_mode
      port "http" {
        to = 8200
      }
    }

    service {
      name     = "vault"
      provider = "nomad"
      port     = "http"
    }

    task "server" {
      driver = "docker"

      config {
        image = "hashicorp/vault:2.1.0"
        ports = ["http"]
        args = [
          "server",
          "-dev",
          "-dev-root-token-id=${var.vault_root_token}",
          "-dev-listen-address=${NOMAD_ALLOC_IP_http}:8200",
        ]
      }

      resources {
        cpu    = 500
        memory = 512
      }
    }
  }
}
