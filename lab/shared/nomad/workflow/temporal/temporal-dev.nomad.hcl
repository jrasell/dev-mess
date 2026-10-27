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

variable "traefik_enabled" {
  description = "Whether to enable Traefik for this job"
  type        = bool
  default     = true
}

variable "traefik_host_header" {
  description = "The Host header to use for Traefik routing"
  type        = string
  default     = "temporal.jrasell.sbx.hashidemos.io"
}

locals {
  service_address_mode = substr(var.network_mode, 0, 4) == "cni/" ? "alloc" : "auto"
  check_address_mode   = substr(var.network_mode, 0, 4) == "cni/" ? "alloc" : "host"

  traefik_ui_tags  = var.traefik_enabled ? [
    "traefik.enable=true",
    "traefik.http.routers.temporal-ui.rule=Host(`${var.traefik_host_header}`)",
    "traefik.http.routers.temporal-ui.entrypoints=web",
  ] : []
}

job "temporal-dev" {
  type      = "service"
  namespace = var.namespace
  node_pool = var.node_pool

  group "temporal" {

    network {
      mode = var.network_mode
      port "api" {
        to = "7233"
      }
      port "ui" {
        to = "8233"
      }
    }

    service {
      address_mode = local.service_address_mode
      provider     = "nomad"
      name         = "temporal-api"
      port         = "api"

      check {
        address_mode = local.check_address_mode
        type         = "tcp"
        interval     = "10s"
        timeout      = "2s"
      }
    }

    service {
      address_mode = local.service_address_mode
      provider     = "nomad"
      name         = "temporal-ui"
      port         = "ui"
      tags         = local.traefik_ui_tags

      check {
        address_mode = local.check_address_mode
        type         = "tcp"
        interval     = "10s"
        timeout      = "2s"
      }
    }

    task "server" {
      driver = "docker"

      config {
        image   = "temporalio/temporal:1.6.2"
        ports   = [ "api", "ui" ]
        command = "server"
        args    = [
          "start-dev",
          "--ip=0.0.0.0",
          "--ui-ip=0.0.0.0",
        ]
      }

      resources {
        cpu    = 500
        memory = 256
      }
    }
  }
}
