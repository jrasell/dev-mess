job "grafana-loki" {

  group "loki" {
    network {
      mode = "bridge"
      port "loki" {
        to = 3100
      }
    }

    service {
      name     = "grafana-loki"
      port     = "loki"
      provider = "nomad"

      check {
        name     = "http_probe"
        type     = "http"
        path     = "/ready"
        interval = "3s"
        timeout  = "1s"
      }
    }

    task "loki" {
      driver = "docker"

      config {
        image = "grafana/loki:2.9.3"
      }

      resources {
        cpu    = 200
        memory = 256
      }
    }
  }
}