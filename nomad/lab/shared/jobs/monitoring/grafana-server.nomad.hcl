job "grafana-server" {

  group "server" {
    network {
      mode = "bridge"
      port "grafana" {
        to = 3000
      }
    }

    service {
      name     = "grafana-server"
      port     = "grafana"
      provider = "nomad"
      tags     = [
        "traefik.enable=true",
        "traefik.http.routers.grafana.entrypoints=web",
        "traefik.http.routers.grafana.rule=PathPrefix(`/grafana/`)",
      ]

      check {
        name     = "http_probe"
        type     = "http"
        path     = "/api/health"
        interval = "5s"
        timeout  = "1s"
      }
    }

    task "server" {
      driver = "docker"

      config {
        image   = "grafana/grafana:9.5.15"
        volumes = [
          "local/datasources:/etc/grafana/provisioning/datasources",
          "local/grafana.ini:/etc/grafana/grafana.ini",
        ]
      }

      template {
        data = <<EOH
apiVersion: 1
datasources:
- name: Prometheus
  type: prometheus
  access: proxy
  url: http://{{ range $i, $s := nomadService "prometheus-server" }}{{ if eq $i 0 }}{{.Address}}:{{.Port}}{{end}}{{end}}/prometheus/
  isDefault: true
  version: 1
  editable: false

- name: Loki
  type: loki
  access: proxy
  url: http://{{ range $i, $s := nomadService "grafana-loki" }}{{ if eq $i 0 }}{{.Address}}:{{.Port}}{{end}}{{end}}
  isDefault: false
  version: 1
  editable: false
EOH

        destination = "local/datasources/datasources.yaml"
      }

      template {
        data = <<EOH
[server]
root_url            = %(protocol)s://%(domain)s:%(http_port)s/grafana/
serve_from_sub_path = true
EOH

        destination = "local/grafana.ini"
      }

      resources {
        cpu    = 200
        memory = 256
      }
    }
  }
}