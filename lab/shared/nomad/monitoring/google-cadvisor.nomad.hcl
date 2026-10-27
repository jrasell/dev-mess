job "google-cadvisor" {
  type = "system"

  group "google-cadvisor" {
    network {
      mode = "bridge"
      port "cadvisor" {
        to = 8080
      }
    }

    service {
      name     = "google-cadvisor"
      port     = "cadvisor"
      provider = "nomad"
      tags     = [
        "traefik.enable=true",
        "traefik.http.routers.cadvisor.entrypoints=web",
        "traefik.http.routers.cadvisor.rule=PathPrefix(`/cadvisor`)",
      ]
    }

    task "google-cadvisor" {
      driver = "docker"

      config {
        image      = "gcr.io/cadvisor/cadvisor:v0.47.2"
        privileged = true
        args       = [
          "-url_base_prefix=/cadvisor",
        ]

        mount {
          type     = "bind"
          target   = "/etc/machine-id"
          source   = "/etc/machine-id"
          readonly = true
          bind_options {
            propagation = "rshared"
          }
        }

        mount {
          type     = "bind"
          target   = "/rootfs"
          source   = "/"
          readonly = true
          bind_options {
            propagation = "rshared"
          }
        }

        mount {
          type     = "bind"
          target   = "/var/run"
          source   = "/var/run"
          readonly = true
          bind_options {
            propagation = "rshared"
          }
        }

        mount {
          type     = "bind"
          target   = "/sys"
          source   = "/sys"
          readonly = true
          bind_options {
            propagation = "rshared"
          }
        }

        mount {
          type     = "bind"
          target   = "/var/lib/docker/"
          source   = "/var/lib/docker/"
          readonly = true
          bind_options {
            propagation = "rshared"
          }
        }

        mount {
          type     = "bind"
          target   = "/dev/disk/"
          source   = "/dev/disk/"
          readonly = true
          bind_options {
            propagation = "rshared"
          }
        }
      }

      resources {
        cpu    = 200
        memory = 256
      }
    }
  }
}