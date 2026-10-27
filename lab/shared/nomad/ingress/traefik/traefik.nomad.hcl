variable "id" {
  type        = string
  description = "The name of the Traefik job"
  default     = "traefik"
}

variable "namespace" {
  type        = string
  description = "The Nomad namespace to deploy Traefik in"
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

variable "traefik_version" {
  type        = string
  description = "The version of Traefik to deploy"
  default     = "v3.7.1"
}

variable "traefik_prefix" {
  type        = string
  description = "The Nomad provider prefix for Traefik when reading service tags"
  default     = "traefik"
}

variable "traefik_ports" {
  type        = map(number)
  description = "The ports and entrypoints for Traefik"
  default     = {
    web     = 80,
    traefik = 8080,
  }
}

locals {
  service_address_mode = substr(var.network_mode, 0, 4) == "cni/" ? "alloc" : "auto"
  check_address_mode   = substr(var.network_mode, 0, 4) == "cni/" ? "alloc" : "host"
}

job "traefik" {
  type      = "system"
  id        = var.id
  name      = var.id
  namespace = var.namespace
  node_pool = var.node_pool

  group "traefik" {
    network {
      mode = var.network_mode
      dynamic "port" {
        for_each = var.traefik_ports
        labels   = [port.key]
        content {
          static = port.value
        }
      }
    }

    dynamic "service" {
      for_each = var.traefik_ports
      content {
        address_mode = local.service_address_mode
        name         = "traefik-${service.key}"
        port         = service.key
        provider     = "nomad"

        check {
          address_mode = local.check_address_mode
          type         = "tcp"
          port         = service.key
          interval     = "10s"
          timeout      = "2s"
        }
      }
    }

    task "traefik" {
      driver = "docker"

      config {
        image   = "traefik:${var.traefik_version}"
        ports   = keys(var.traefik_ports)
        volumes = [
          "local/traefik.yml:/etc/traefik/traefik.yml",
        ]
      }

      identity {
        env           = true
        change_mode   = "restart"
      }

      template {
        destination = "${NOMAD_TASK_DIR}/traefik.yml"
        data        = <<-EOH
api:
  insecure: true
  dashboard: true

entryPoints:
%{~ for name, port in var.traefik_ports }
  ${name}:
    address: ":${port}"
%{~ endfor }

log:
  level: DEBUG

ping: {}

providers:
  nomad:
    exposedByDefault: false
    prefix: ${var.traefik_prefix}
    stale: true
    endpoint:
      address: unix://{{ env "NOMAD_SECRETS_DIR" }}/api.sock
EOH
      }

      resources {
        cpu    = 1000
        memory = 1024
      }
    }
  }
}
