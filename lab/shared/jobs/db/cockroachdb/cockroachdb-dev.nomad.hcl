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

job "cockroachdb-dev" {
  type      = "service"
  namespace = var.namespace

  group "cockroachdb" {

    network {
      mode = var.network_mode
      port "rpc" {
        to = "26257"
      }
      port "http" {
        to = "8080"
      }
    }

    service {
      address_mode = local.service_address_mode
      provider     = "nomad"
      name         = "cockroachdb-rpc"
      port         = "rpc"

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
      name         = "cockroachdb-http"
      port         = "http"

      check {
        address_mode = local.check_address_mode
        type         = "tcp"
        interval     = "10s"
        timeout      = "2s"
      }
    }

    task "db" {
      driver = "docker"

      config {
        image   = "cockroachdb/cockroach:v25.4.2"
        ports   = [ "rpc", "http" ]
        command = "start-single-node"
        args    = [
          "--insecure",
        ]
      }

      resources {
        cpu    = 500
        memory = 512
      }
    }
  }
}
