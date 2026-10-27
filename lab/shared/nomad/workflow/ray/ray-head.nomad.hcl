variable "namespace" {
  description = "The Nomad namespace to deploy to"
  type        = string
  default     = "default"
}

job "ray-head" {
  type      = "service"
  namespace = var.namespace

  group "head" {

    network {
      mode = "bridge"
      port "client" {
        to = 10001
      }
      port "dashboard" {
        to = 8265
      }
      port "redis" {
        to = 6379
      }
      port "object_manager" {
        to = 8076
      }
      port "serve" {
        to = 8000
      }
    }

    task "ray-head" {
      driver = "docker"

      config {
        image   = "rayproject/ray:latest"
        command = "ray"
        args    = [
          "start",
          "--head",
          "--dashboard-host=0.0.0.0",
          "--redis-password=",
          "--block"
        ]

        ports = ["client", "dashboard", "redis", "object_manager", "serve"]
      }

      env {
        RAY_DISABLE_DOCKER_CPU_WARNING = "1"
        RAY_scheduler_spread_threshold = "0.0"
      }

      resources {
        cpu    = 2000
        memory = 2048
      }

      service {
        name     = "ray-head"
        provider = "nomad"
        port     = "dashboard"
      }

      service {
        name     = "ray-gcs"
        provider = "nomad"
        port     = "redis"
      }
    }
  }
}
