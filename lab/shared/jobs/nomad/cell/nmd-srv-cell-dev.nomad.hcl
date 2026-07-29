variable "id_prefix" {
  type        = string
  description = "The ID prefix to use for the job; prefixed to the agent region"
  default     = "nmd-srv-cell-dev"
}

variable "namespace" {
  type        = string
  description = "The Nomad namespace to the job into"
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

variable "nomad_agent_region" {
  type        = string
  description = "The Nomad region to configure the agent for"
  default     = "global"
}

variable "nomad_agent_num" {
  type        = number
  description = "The number of Nomad agents to deploy in the job"
  default     = 3
}

locals {
  job_id                        = "${var.id_prefix}-${var.nomad_agent_region}"
  service_address_mode          = substr(var.network_mode, 0, 4) == "cni/" ? "alloc" : "auto"
  nomad_advertise_lookup_prefix = substr(var.network_mode, 0, 4) == "cni/" ? "NOMAD_ALLOC_ADDR" : "NOMAD_ADDR"
}

job "nmd-srv-cell-dev" {
  id        = local.job_id
  name      = local.job_id
  namespace = var.namespace
  node_pool = var.node_pool

  group "server" {
    count          = var.nomad_agent_num
    shutdown_delay = "10s"

    network {
      mode = var.network_mode

      port "http" {
        to = "4646"
      }
      port "rpc" {
        to = "4647"
      }
      port "serf" {
        to = "4648"
      }
    }

    service {
      address_mode = local.service_address_mode
      name         = "${local.job_id}-http"
      port         = "http"
      provider     = "nomad"
    }

    service {
      address_mode = local.service_address_mode
      name         = "${local.job_id}-rpc"
      port         = "rpc"
      provider     = "nomad"
    }

    service {
      address_mode = local.service_address_mode
      name         = "${local.job_id}-serf"
      port         = "serf"
      provider     = "nomad"
    }

    task "agent" {
      driver = "docker"

      config {
        image = "hashicorp/nomad:2.0.4"
        ports = ["http", "rpc", "serf"]
        args  = [
          "agent",
          "-config=${NOMAD_TASK_DIR}/config.hcl"
        ]
      }

      template {
        data = <<EOH
bind_addr    = "{{ env "NOMAD_ALLOC_IP_http" }}"
data_dir     = "{{ env "NOMAD_ALLOC_DIR" }}/nomad/"
region       = "${var.nomad_agent_region}"
log_level    = "INFO"

advertise {
  http = "{{ env "${local.nomad_advertise_lookup_prefix}_http" }}"
  rpc  = "{{ env "${local.nomad_advertise_lookup_prefix}_rpc" }}"
  serf = "{{ env "${local.nomad_advertise_lookup_prefix}_serf" }}"
}

server {
  enabled          = true
  bootstrap_expect = ${var.nomad_agent_num}

  server_join {
    retry_join = [
    {{- range nomadService "${local.job_id}-serf" }}
    "{{ .Address}}:{{ .Port }}",{{- end }}
    ]
  }
}
EOH

        change_mode = "restart"
        destination = "${NOMAD_TASK_DIR}/config.hcl"
      }

      resources {
        cpu    = 1000
        memory = 1024
      }
    }
  }
}
