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

job "temporal-dev" {
  type      = "service"
  namespace = var.namespace

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
      address_mode = local.address_mode
      provider     = "nomad"
      name         = "temporal-ui"
      port         = "ui"

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
        image   = "temporalio/temporal:1.5.1"
        ports   = [ "api", "ui" ]
        command = "server"
        args    = [
          "start-dev",
          "--ip=${NOMAD_ALLOC_IP_api}",
          "--ui-ip=${NOMAD_ALLOC_IP_ui}",
        ]
      }

      resources {
        cpu    = 500
        memory = 256
      }
    }
  }
}
