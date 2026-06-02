variable "id" {
  type        = string
  description = "The name of the Airflow job"
  default     = "airflow-standalone"
}

variable "namespace" {
  description = "The Nomad namespace to deploy to"
  type        = string
  default     = "default"
}

variable "node_pool" {
  description = "The node pool to target for this job"
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

job "airflow-standalone" {
  type      = "service"
  id        = var.id
  name      = var.id
  namespace = var.namespace
  node_pool = var.node_pool

  group "airflow" {

    network {
      mode = var.network_mode
      port "ui" {
        to = "8080"
      }
    }

    shutdown_delay = "10s"

    service {
      address_mode = local.service_address_mode
      provider     = "nomad"
      name         = "airflow-ui"
      port         = "ui"
    }

    task "airflow" {
      driver = "docker"

      config {
        image   = "apache/airflow:slim-3.2.2"
        ports   = [ "ui" ]
        command = "standalone"
      }

      resources {
        cpu    = 2000
        memory = 2048
      }
    }
  }
}
