variable "id_prefix" {
  type        = string
  description = "The ID prefix to use for the job; prefixed to the agent region"
  default     = "nmd-ndsm-cell-dev"
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

variable "nomad_agent_allocs" {
  type        = number
  description = "The number of Nomad agents allocs to deploy"
  default     = 1
}

variable "nomad_clients_per_alloc" {
  type        = number
  description = "The number of Nomad agents to run per allocation"
  default     = 10
}

variable "srv_id_prefix" {
  type        = string
  description = "The ID prefix of the server job; used to look up RPC service addresses"
  default     = "nmd-srv-cell-dev"
}

locals {
  job_id                        = "${var.id_prefix}-${var.nomad_agent_region}"
  srv_job_id                    = "${var.srv_id_prefix}-${var.nomad_agent_region}"
  service_address_mode          = substr(var.network_mode, 0, 4) == "cni/" ? "alloc" : "auto"
  nomad_advertise_lookup_prefix = substr(var.network_mode, 0, 4) == "cni/" ? "NOMAD_ALLOC_ADDR" : "NOMAD_ADDR"
}

job "nmd-ndsm-cell-dev" {
  id        = local.job_id
  name      = local.job_id
  namespace = var.namespace
  node_pool = var.node_pool

  group "client" {
    count          = var.nomad_agent_allocs
    shutdown_delay = "10s"

    network {
      mode = var.network_mode
    }

    task "agent" {
      driver = "docker"

      config {
        image   = "jrasell/nomad-nodesim:2.0.5"
        command = "/bin/nomad-nodesim"
        args    = ["-config", "/local/config.hcl"]
        cap_add = ["SYS_ADMIN"]

        mount {
          type     = "bind"
          target   = "/sys/fs/cgroup"
          source   = "/sys/fs/cgroup"
          readonly = false
        }
      }

      template {
        data = <<EOH
work_dir         = "/local/"
node_num         = ${var.nomad_clients_per_alloc}
server_addr      = [
  {{- range nomadService "${local.srv_job_id}-rpc" }}
  "{{ .Address }}:{{ .Port }}",
  {{- end }}
]

log {
  level            = "info"
  json             = true
  include_location = true
}

node {
  datacenter = "{{ env "NOMAD_SHORT_ALLOC_ID" }}"
  region     = "${var.nomad_agent_region}"
  node_pool  = "default"

  options = {
    "fingerprint.denylist" = "env_aws,env_gce,env_azure,env_digitalocean"
  }

  # Rough example of an AWS g4dn.16xlarge instance assuming a 2.4GHz CPU clock
  # speed.
  resources {
    cpu_compute = 256000
    memory_mb   = 160000
  }
}
EOH
        change_mode = "restart"
        destination = "/local/config.hcl"
      }

      resources {
        cpu    = 1000
        memory = 1024
      }
    }
  }
}
