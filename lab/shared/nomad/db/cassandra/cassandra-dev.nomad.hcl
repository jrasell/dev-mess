variable "job_name" {
  type        = string
  default     = "cassandra-dev"
  description = "The name to give to the Nomad job"
}

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

job "cassandra-dev" {
  name      = var.job_name
  namespace = var.namespace
  node_pool = var.node_pool

  group "cassandra" {

    network {
      mode = var.network_mode
      port "cqlsh" {
        to = 9042
      }
    }

    service {
      address_mode = local.service_address_mode
      name         = var.job_name
      port         = "cqlsh"
      provider     = "nomad"
    }

    task "cassandra" {
      driver = "docker"

      config {
        image = "cassandra:5.0.8"
        ports = ["cqlsh"]
      }

      resources {
        cpu    = 1000
        memory = 2048
      }
    }
  }
}
