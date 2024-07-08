job "prometheus-node-exporter" {
  type = "system"

  group "prometheus-node-exporter" {

    network {
      mode = "bridge"
      port "metrics" {}
    }

    service {
      name     = "prometheus-node-exporter"
      port     = "metrics"
      provider = "nomad"

      check {
        type     = "tcp"
        port     = "metrics"
        interval = "10s"
        timeout  = "1s"
      }
    }

    task "prometheus-node-exporter" {
      driver = "docker"

      config {
        image = "quay.io/prometheus/node-exporter:v1.7.0"
        args  = [
          "--path.rootfs=/host",
          "--web.listen-address=:${NOMAD_PORT_metrics}",
        ]

        mount {
          type     = "bind"
          target   = "/host"
          source   = "/"
          readonly = true
          bind_options {
            propagation = "rshared"
          }
        }
      }

      resources {
        cpu    = 100
        memory = 126
      }
    }
  }
}