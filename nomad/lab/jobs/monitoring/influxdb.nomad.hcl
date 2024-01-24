variable "influxdb_bucket_name" {
  type        = string
  default     = "default"
  description = "The initial InfluxDB bucket to create."
}

variable "influxdb_org_name" {
  type        = string
  default     = "jrasell"
  description = "The initial InfluxDB organization to create."
}

variable "influxdb_admin_password" {
  type        = string
  default     = "jR;b4`8D=t%])c{yk-d~uq"
  description = "The password to associate with the admin user."
}

job "influxdb" {

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
        DOCKER_INFLUXDB_INIT_PASSWORD = var.influxdb_admin_password
        DOCKER_INFLUXDB_INIT_ORG      = var.influxdb_org_name
        DOCKER_INFLUXDB_INIT_BUCKET   = var.influxdb_bucket_name
      }

      resources {
        cpu    = 200
        memory = 256
      }
    }
  }
}
