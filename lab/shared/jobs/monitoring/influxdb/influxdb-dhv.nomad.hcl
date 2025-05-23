variable "nomad_deployment_namespace" {
  type        = string
  description = "The Nomad namespace to deploy the job within."
  default     = "default"
}

job "influxdb-dhv" {

  type      = "service"
  namespace = var.nomad_deployment_namespace

  group "influxdb" {

    network {
      mode = "bridge"
      port "influxdb" {
        to = 8086
      }
    }

    service {
      name     = "influxdb"
      port     = "influxdb"
      provider = "nomad"

      check {
        name     = "influxdb_http_probe"
        type     = "http"
        path     = "/health"
        interval = "5s"
        timeout  = "1s"
      }
    }

    volume "influxdb" {
      type   = "host"
      source = "influxdb"
    }

    task "influxdb" {
      driver = "docker"

      config {
        image = "influxdb:2.7.5"
        ports = ["influxdb"]
        args  = [
          "--http-bind-address=0.0.0.0:8086",
        ]
      }

      env {
        DOCKER_INFLUXDB_INIT_MODE     = "setup"
        DOCKER_INFLUXDB_INIT_USERNAME = "admin"
        DOCKER_INFLUXDB_INIT_PASSWORD = "password"
        DOCKER_INFLUXDB_INIT_ORG      = "jrasell"
        DOCKER_INFLUXDB_INIT_BUCKET   = "default"
      }

      volume_mount {
        volume      = "influxdb"
        destination = "/var/lib/influxdb2/"
      }

      resources {
        cpu    = 200
        memory = 256
      }
    }
  }
}
