variable "id" {
  description = "The name of the Victoria Metrics job"
  type        = string
  default     = "victoria-metrics-standalone"
}

variable "namespace" {
  description = "The Nomad namespace to deploy Victoria Metrics in"
  type        = string
  default     = "default"
}

variable "node_pool" {
  description = "The node pool to target for this job"
  type        = string
  default     = "default"
}

variable "network_mode" {
  description = "The network mode to use"
  type        = string
  default     = "bridge"
}

locals {
  service_address_mode = substr(var.network_mode, 0, 4) == "cni/" ? "alloc" : "auto"
  check_address_mode   = substr(var.network_mode, 0, 4) == "cni/" ? "alloc" : "host"
}

job "victoria-metrics-standalone" {
  id        = var.id
  name      = var.id
  namespace = var.namespace
  node_pool = var.node_pool

  group "server" {
    network {
      mode = var.network_mode
      port "http" {
        to = 8428
      }
    }

    shutdown_delay = "5s"

    service {
      address_mode = local.service_address_mode
      name         = "victoria-metrics-http"
      port         = "http"
      provider     = "nomad"

      check {
        address_mode = local.check_address_mode
        name         = "victoria_metrics_health"
        type         = "http"
        path         = "/health"
        interval     = "10s"
        timeout      = "2s"
      }
    }

    task "server" {
      driver = "docker"

      config {
        image = "victoriametrics/victoria-metrics:v1.144.0"
        ports = ["http"]
        args = [
          "-storageDataPath=${NOMAD_ALLOC_DIR}/data",
          "-retentionPeriod=30d",
          "-httpListenAddr=0.0.0.0:8428",
          "-search.maxUniqueTimeseries=300000",
          "-search.maxConcurrentRequests=16",
          "-search.latencyOffset=10s",
          "-selfScrapeInterval=15s",
        ]
      }

      resources {
        cpu    = 500
        memory = 512
      }
    }
  }
}
