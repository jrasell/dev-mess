job "grafana-promtail" {
  type = "system"

  group "promtail" {
    network {
      port "http" {}
    }

    service {
      name     = "grafana-promtail"
      port     = "http"
      provider = "nomad"

      check {
        name     = "http_probe"
        type     = "http"
        path     = "/ready"
        interval = "10s"
        timeout  = "2s"
      }
    }

    task "promtail" {
      driver = "docker"

      template {
        data = <<-EOH
---
server:
  http_listen_port: {{ env "NOMAD_PORT_http" }}
positions:
  filename: /tmp/positions.yaml
clients:
  - url: http://{{ range $i, $s := nomadService "grafana-loki" }}{{ if eq $i 0 }}{{.Address}}:{{.Port}}{{end}}{{end}}/loki/api/v1/push
scrape_configs:
  - job_name: allocs
    static_configs:
    - targets:
      - localhost
      labels:
        __path__: /opt/nomad/data/alloc/*/alloc/logs/*std*.{?,??}
EOH
        destination = "${NOMAD_TASK_DIR}/promtail-config.yaml"
      }

      config {
        image        = "grafana/promtail:2.7.4"
        privileged   = true
        network_mode = "host"
        args = [
          "-config.file=${NOMAD_TASK_DIR}/promtail-config.yaml"
        ]

        mount {
          type     = "bind"
          target   = "/etc/machine-id"
          source   = "/etc/machine-id"
          readonly = false
          bind_options {
            propagation = "rshared"
          }
        }

        mount {
          type     = "bind"
          target   = "/opt/nomad/data/alloc"
          source   = "/opt/nomad/data/alloc"
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