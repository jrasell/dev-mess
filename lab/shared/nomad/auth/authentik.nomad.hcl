variable "authentik_secret_key" {
  description = "The secret key to configure the server and worker with."
  type        = string
  default     = "MkXYatGBz7o/TIeQI0mFeD5Sm2v5Osd8"
}

variable "authentik_initial_password" {
  description = "Initial password to set for the akadmin user."
  type        = string
  default     = "password"
}

job "authentik" {

  count = 1

  group "authentik" {

    network {
      mode = "bridge"
      port "postgres" {
        to = "5432"
      }
      port "redis" {
        to = "6379"
      }
      port "authentik-http" {
        to = "9000"
      }
    }

    service {
      name     = "authentik-postgres"
      port     = "postgres"
      provider = "nomad"
    }
    service {
      name     = "authentik-redis"
      port     = "redis"
      provider = "nomad"
    }
    service {
      name     = "authentik-http"
      port     = "authentik-http"
      provider = "nomad"
    }

    task "postgres" {
      lifecycle {
        hook    = "prestart"
        sidecar = true
      }

      driver  = "docker"

      config {
        image = "docker.io/library/postgres:17"
      }

      env {
        POSTGRES_PASSWORD = "authentik"
        POSTGRES_USER     = "authentik"
        POSTGRES_DB       = "authentik"
      }

      resources {
        cpu    = 150
        memory = 256
      }
    }

    task "redis" {
      lifecycle {
        hook    = "prestart"
        sidecar = true
      }
      
      driver  = "docker"

      config {
        image = "docker.io/library/redis:7.4.2"
      }

      resources {
        cpu    = 150
        memory = 256
      }
    }

    task "authentik-server" {
      driver  = "docker"

      config {
        image   = "ghcr.io/goauthentik/server:2024.12.2"
        command = "server"
      }

      env {
        AUTHENTIK_SECRET_KEY           = var.authentik_secret_key
        AUTHENTIK_REDIS__HOST          = "127.0.0.1"
        AUTHENTIK_REDIS__PORT          = "6379"
        AUTHENTIK_POSTGRESQL__HOST     = "127.0.0.1"
        AUTHENTIK_POSTGRESQL__PORT     = "5432"
        AUTHENTIK_POSTGRESQL__USER     = "authentik"
        AUTHENTIK_POSTGRESQL__NAME     = "authentik"
        AUTHENTIK_POSTGRESQL__PASSWORD = "authentik"
      }

      resources {
        cpu    = 500
        memory = 1024
      }
    }

    task "authentik-worker" {
      driver  = "docker"

      config {
        image   = "ghcr.io/goauthentik/server:2024.12.2"
        command = "worker"
      }

      env {
        AUTHENTIK_SECRET_KEY           = var.authentik_secret_key
        AUTHENTIK_BOOTSTRAP_PASSWORD   = var.authentik_initial_password
        AUTHENTIK_REDIS__HOST          = "127.0.0.1"
        AUTHENTIK_REDIS__PORT          = "6379"
        AUTHENTIK_POSTGRESQL__HOST     = "127.0.0.1"
        AUTHENTIK_POSTGRESQL__PORT     = "5432"
        AUTHENTIK_POSTGRESQL__USER     = "authentik"
        AUTHENTIK_POSTGRESQL__NAME     = "authentik"
        AUTHENTIK_POSTGRESQL__PASSWORD = "authentik"
      }

      resources {
        cpu    = 500
        memory = 1024
      }
    }
  }
}