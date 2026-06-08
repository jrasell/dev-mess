variable "id" {
  type        = string
  description = "The name of the Tetragon job"
  default     = "tetragon"
}

variable "namespace" {
  type        = string
  description = "The Nomad namespace to deploy Tetragon in"
  default     = "default"
}

variable "node_pool" {
  description = "The node pool to target for this job"
  type        = string
  default     = "all"
}

variable "network_mode" {
  description = "The network mode to use"
  type        = string
  default     = "bridge"
}

variable "vector_victorialogs_enabled" {
  description = "Whether to run a Vector sidecar to ship Tetragon logs to Victoria Logs"
  type        = bool
  default     = false
}

locals {
  service_address_mode = substr(var.network_mode, 0, 4) == "cni/" ? "alloc" : "auto"
}

job "tetragon" {
  type      = "system"
  id        = var.id
  name      = var.id
  namespace = var.namespace
  node_pool = var.node_pool

  group "tetragon" {
    network {
      mode = var.network_mode

      port "tetragon-metrics" {
        to = 2112
      }
    }

    shutdown_delay = "10s"

    service {
      address_mode = local.service_address_mode
      name         = "tetragon-metrics"
      port         = "tetragon-metrics"
      provider     = "nomad"
    }

    task "tetragon" {
      driver = "docker"

      config {
        image      = "quay.io/cilium/tetragon:v1.7.0"
        privileged = true
        pid_mode   = "host"
        args       = [
          "--metrics-server=:2112",
          "--export-filename=/var/log/tetragon.log",
        ]
        ports = ["tetragon-metrics"]

        mount {
          type     = "bind"
          target   = "/var/lib/tetragon/btf"
          source   = "/sys/kernel/btf/vmlinux"
          readonly = true
        }

        mount {
          type   = "bind"
          target = "/var/log"
          source = "/var/log"
          bind_options {
            propagation = "rshared"
          }
        }

        mount {
          type     = "bind"
          target   = "/sys/kernel"
          source   = "/sys/kernel"
          readonly = true
          bind_options {
            propagation = "rshared"
          }
        }
      }

      resources {
        cpu    = 1000
        memory = 1024
      }
    }

    dynamic "task" {
      for_each = var.vector_victorialogs_enabled ? [1] : []
      labels   = ["vector"]

      content {
        driver = "docker"

        template {
          data = <<-EOH
[sources.tetragon]
type    = "file"
include = ["/var/log/tetragon.log"]
data_dir = "{{ env "NOMAD_TASK_DIR" }}"

[transforms.parse]
type   = "remap"
inputs = ["tetragon"]
source = """
. = parse_json!(.message)
._msg = join!([.node_name, "Tetragon event"], " ")
"""

[sinks.victoria_logs]
type        = "elasticsearch"
inputs      = ["parse"]
endpoints   = ["http://{{ range $i, $s := nomadService "victoria-logs-http" }}{{ if eq $i 0 }}{{ .Address }}:{{ .Port }}{{ end }}{{ end }}/insert/elasticsearch/"]
mode        = "bulk"
api_version = "v8"
compression = "gzip"

[sinks.victoria_logs.query]
_time_field    = "time"
_stream_fields = "node_name"

[sinks.victoria_logs.batch]
max_bytes    = 10485760
timeout_secs = 1

[sinks.victoria_logs.healthcheck]
enabled = false
EOH

          destination = "${NOMAD_TASK_DIR}/vector.toml"
        }

        config {
          image = "timberio/vector:0.49.0-alpine"
          args  = ["--config", "${NOMAD_TASK_DIR}/vector.toml"]

          mount {
            type     = "bind"
            target   = "/var/log/tetragon.log"
            source   = "/var/log/tetragon.log"
            readonly = true
            bind_options {
              propagation = "rshared"
            }
          }
        }

        resources {
          cpu    = 100
          memory = 128
        }
      }
    }
  }
}
