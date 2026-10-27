variable "id" {
  description = "The name of the OpenObserve job"
  type        = string
  default     = "openobserve-standalone"
}

variable "namespace" {
  description = "The Nomad namespace to deploy OpenObserve in"
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

variable "root_user_email" {
  description = "The root user email for OpenObserve"
  type        = string
  default     = "jrasell@example.com"
}

variable "root_user_password" {
  description = "The root user password for OpenObserve"
  type        = string
  default     = "password"
}

locals {
  service_address_mode = substr(var.network_mode, 0, 4) == "cni/" ? "alloc" : "auto"
  check_address_mode   = substr(var.network_mode, 0, 4) == "cni/" ? "alloc" : "host"
}

job "openobserve-standalone" {
  id        = var.id
  name      = var.id
  namespace = var.namespace
  node_pool = var.node_pool

  group "openobserve" {
    network {
      mode = var.network_mode

      port "http" {
        to = 5080
      }
    }

    shutdown_delay = "10s"

    service {
      address_mode = local.service_address_mode
      name         = "openobserve"
      port         = "http"
      provider     = "nomad"

      check {
        address_mode = local.check_address_mode
        type         = "http"
        path         = "/healthz"
        interval     = "10s"
        timeout      = "2s"
      }
    }

    task "openobserve" {
      driver = "docker"

      config {
        image = "public.ecr.aws/zinclabs/openobserve:v0.90.3"
        ports = ["http"]
      }

      env {
        ZO_DATA_DIR           = "/data"
        ZO_ROOT_USER_EMAIL    = var.root_user_email
        ZO_ROOT_USER_PASSWORD = var.root_user_password
        ZO_TELEMETRY          = "false"
      }

      resources {
        cpu    = 500
        memory = 512
      }
    }
  }
}
