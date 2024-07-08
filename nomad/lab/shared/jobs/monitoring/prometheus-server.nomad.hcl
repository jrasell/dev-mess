job "prometheus-server" {

  group "server" {
    network {
      mode = "bridge"
      port "prometheus" {
        to = 9090
      }
    }

    service {
      name     = "prometheus-server"
      port     = "prometheus"
      provider = "nomad"
      tags     = [
        "traefik.enable=true",
        "traefik.http.routers.prometheus.entrypoints=web",
        "traefik.http.routers.prometheus.rule=PathPrefix(`/prometheus/`)",
      ]

      check {
        name     = "prometheus_http_probe"
        type     = "http"
        path     = "/prometheus/-/healthy"
        interval = "5s"
        timeout  = "1s"
      }
    }

    task "server" {
      driver = "docker"
      config {
        image = "prom/prometheus:v2.45.2"
        ports = ["prometheus"]
        args  = [
          "--config.file=${NOMAD_TASK_DIR}/config/prometheus.yml",
          "--storage.tsdb.path=/prometheus",
          "--web.listen-address=0.0.0.0:9090",
          "--web.console.libraries=/usr/share/prometheus/console_libraries",
          "--web.console.templates=/usr/share/prometheus/consoles",
          "--web.external-url=/prometheus/",
        ]

        volumes = [
          "local/config:/etc/prometheus/config",
        ]
      }

      template {
        data        = file("./.tls/nomad-agent-ca.pem")
        destination = "${NOMAD_TASK_DIR}/ca.pem"
      }

      template {
        data = <<EOH
---
global:
  scrape_interval:     1s
  evaluation_interval: 1s

scrape_configs:
  - job_name: "prometheus_server"
    metrics_path: "/prometheus/metrics"
    static_configs:
      - targets:
        - 0.0.0.0:9090

  - job_name: "nomad_server"
    metrics_path: "/v1/metrics"
    scheme: "https"
    params:
      format:
        - "prometheus"
    tls_config:
      ca_file: "/local/ca.pem"
      server_name: "server.uk1.nomad"
    static_configs:
      - targets:
        - 192.168.1.110:4646
        - 192.168.1.111:4646
        - 192.168.1.112:4646

  - job_name: "nomad_client"
    metrics_path: "/v1/metrics"
    scheme: "https"
    params:
      format:
        - "prometheus"
    tls_config:
      ca_file: "/local/ca.pem"
      server_name: "client.uk1.nomad"
    static_configs:
      - targets:
        - 192.168.1.120:4646
        - 192.168.1.121:4646

  - job_name: "prometheus_node_exporter"
    metrics_path: "/metrics"
    static_configs:
      - targets:
        {{- range nomadService "prometheus-node-exporter" }}
        - {{ .Address }}:{{ .Port }}{{- end }}
        - 192.168.1.110:9100
        - 192.168.1.111:9100
        - 192.168.1.112:9100

  - job_name: "prometheus_nomad_exporter"
    metrics_path: "/metrics"
    static_configs:
      - targets:
        {{- range nomadService "prometheus-nomad-exporter" }}
        - {{ .Address }}:{{ .Port }}{{- end }}

  - job_name: "google_cadvisor"
    metrics_path: "/cadvisor/metrics"
    static_configs:
      - targets:
        {{- range nomadService "google-cadvisor" }}
        - {{ .Address }}:{{ .Port }}{{- end }}
EOH

        change_mode   = "signal"
        change_signal = "SIGHUP"
        destination   = "local/config/prometheus.yml"
      }

      resources {
        cpu    = 500
        memory = 512
      }
    }
  }
}
