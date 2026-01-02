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
      provider = "nomad"
      name     = "temporal-api"
      port     = "api"

      check {
        type     = "tcp"
        interval = "10s"
        timeout  = "2s"
      }
    }

    service {
      provider = "nomad"
      name     = "temporal-ui"
      port     = "ui"

      check {
        type     = "tcp"
        interval = "10s"
        timeout  = "2s"
      }
    }

    task "server" {
      driver = "docker"

      config {
        image   = "temporalio/temporal:1.5.1"
        ports   = [ "api", "ui" ]
        command = "server"
        args    = ["start-dev", "--ip=0.0.0.0", "--ui-ip=0.0.0.0"]
      }

      resources {
        cpu    = 500
        memory = 256
      }
    }
  }
}
