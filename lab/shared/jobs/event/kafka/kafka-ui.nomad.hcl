variable "node_pool" {
  type        = string
  default     = "all"
  description = "The node pool to target for this job"
}

variable "namespace" {
  description = "The Nomad namespace to deploy to"
  type        = string
  default     = "default"
}

variable "network_mode" {
  description = "The network mode to use"
  type        = string
  default     = "bridge"
}

job "kafka-ui" {
  type        = "service"
  node_pool   = var.node_pool
  namespace   = var.namespace

  group "kafka-ui" {

    network {
      mode = var.network_mode
      port "http" {
        to = 8080
      }
    }

    service {
      name     = "kafka-ui"
      provider = "nomad"
      port     = "http"
    }

    task "kafka-ui" {
      driver = "docker"

      config {
        image = "provectuslabs/kafka-ui:v0.7.2"
        ports = ["http"]
      }

      template {
        destination = "local/kafka-ui.env"
        env         = true
        change_mode = "restart"

        data = <<-EOT
KAFKA_CLUSTERS_0_NAME=dev
KAFKA_CLUSTERS_0_BOOTSTRAPSERVERS={{- range $i, $s := nomadService "kafka-broker-external" -}}{{- if gt $i 0 -}},{{- end -}}{{ $s.Address }}:{{ $s.Port }}{{- end }}
SERVER_PORT=8080
EOT
      }

      resources {
        cpu    = 300
        memory = 512
      }
    }
  }
}
