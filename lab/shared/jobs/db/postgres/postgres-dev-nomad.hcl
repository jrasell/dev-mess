variable "node_pool" {
  type        = string
  default     = "all"
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

locals {
  service_address_mode = substr(var.network_mode, 0, 4) == "cni/" ? "alloc" : "auto"
  check_address_mode   = substr(var.network_mode, 0, 4) == "cni/" ? "alloc" : "host"
}

job "postgres-dev" {
  namespace = var.namespace
  node_pool = var.node_pool

  group "postgres" {

    network {
      mode = var.network_mode
      port "db" {
        to = 5432
      }
    }

    service {
      address_mode = local.service_address_mode
      name         = "postgres"
      port         = "db"
      provider     = "nomad"

      check {
        address_mode = local.check_address_mode
        name         = "alive"
        type         = "tcp"
        interval     = "10s"
        timeout      = "2s"
      }
    }

    task "postgres" {
      driver = "docker"

      config {
        image = "postgres:18.3-alpine3.23"
        ports = ["db"]
      }

      env {
        POSTGRES_DB       = "default"
        POSTGRES_USER     = "default"
        POSTGRES_PASSWORD = "Poa2t7OdSvjBPRHj"
      }

      resources {
        cpu    = 500
        memory = 512
      }
    }
  }
}
