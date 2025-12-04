variable "namespace" {
  description = "The Nomad namespace to deploy to"
  type        = string
  default     = "default"
}

job "ray-worker" {
  type      = "service"
  namespace = var.namespace

  group "worker" {
    count = 2

    network {
      mode = "bridge"
      port "object_manager" {
        to = 8076
      }
      port "metrics" {
        to = 8080
      }
    }

    task "ray-worker" {
      driver = "docker"

      config {
        image   = "rayproject/ray:latest"
        command = "ray"
        args    = [
          "start",
          "--address=${RAY_ADDRESS}",
          "--redis-password=",
          "--block"
        ]

        ports = ["object_manager", "metrics"]
      }

      template {
        data = <<EOH
{{- range nomadService "ray-gcs" }}
RAY_ADDRESS="{{ .Address }}:{{ .Port }}"
{{- end }}
EOH

        destination = "local/ray-env"
        env         = true
        change_mode = "restart"
      }

      env {
        RAY_DISABLE_DOCKER_CPU_WARNING = "1"
      }

      resources {
        cpu    = 1000
        memory = 1024
      }
    }
  }
}
