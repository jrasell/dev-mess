job "traefik" {
  type = "system"

  group "traefik" {
    network {
      mode = "bridge"
      port "router" {
        static = 80
      }
      port "api" {
        static = 8080
      }
    }

    service {
      name     = "traefik-router"
      port     = "router"
      provider = "nomad"

      check {
        type     = "tcp"
        port     = "router"
        interval = "10s"
        timeout  = "2s"
      }
    }

    service {
      name     = "traefik-api"
      port     = "api"
      provider = "nomad"

      check {
        type     = "http"
        port     = "api"
        path     = "/ping"
        interval = "10s"
        timeout  = "2s"
      }
    }

    task "traefik" {
      driver = "docker"

      config {
        image   = "traefik:v3.0"
        volumes = [
          "local/traefik.yml:/etc/traefik/traefik.yml",
        ]
      }

      identity {
        env           = true
        change_mode   = "restart"
      }

      template {
        destination = "${NOMAD_TASK_DIR}/traefik.yml"
        data        = <<-EOH
api:
  insecure: true
  dashboard: true

entryPoints:
  web:
    address: ":80"

log:
  level: DEBUG

ping: {}

providers:
  nomad:
    exposedByDefault: false
    prefix: traefik
    stale: true
    endpoint:
      address: unix://{{ env "NOMAD_SECRETS_DIR" }}/api.sock
EOH
      }

      resources {
        cpu    = 100
        memory = 128
      }
    }
  }
}