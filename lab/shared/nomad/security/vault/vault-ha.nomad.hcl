variable "id" {
  type        = string
  description = "The name of the job"
  default     = "vault-ha"
}

variable "node_pool" {
  type        = string
  default     = "default"
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

job "vault-ha" {
  type      = "service"
  id        = var.id
  name      = var.id
  node_pool = var.node_pool
  namespace = var.namespace

  group "vault-1" {
    shutdown_delay = "15s"

    network {
      mode = var.network_mode
      port "http" {
        to = 8200
      }
      port "cluster" {
        to = 8201
      }
    }

    volume "vault-data" {
      type      = "host"
      source    = "vault-1"
      read_only = false
    }

    service {
      name     = "vault-http"
      provider = "nomad"
      port     = "http"

      check {
        name     = "vault_http_probe"
        type     = "http"
        path     = "/v1/sys/health?standbyok=true&sealedcode=200&uninitcode=200"
        interval = "10s"
        timeout  = "2s"
      }
    }

    service {
      name     = "vault-cluster"
      provider = "nomad"
      port     = "cluster"
    }

    task "vault" {
      driver = "docker"

      config {
        image = "hashicorp/vault:2.1.0"
        ports = ["http", "cluster"]
        args  = ["server", "-config=${NOMAD_TASK_DIR}/vault.hcl"]
      }

      volume_mount {
        volume      = "vault-data"
        destination = "/vault/data"
      }

      template {
        destination = "${NOMAD_TASK_DIR}/vault.hcl"
        change_mode = "restart"
        splay       = "30s"

        data = <<-EOT
ui            = true
disable_mlock = true
log_level     = "info"

storage "raft" {
  path    = "/vault/data"
  node_id = "vault-1"

  {{- range nomadService "vault-http" }}
  retry_join {
    leader_api_addr = "http://{{ .Address }}:{{ .Port }}"
  }
  {{ end -}}
}

listener "tcp" {
  address       = "{{ env "NOMAD_ALLOC_ADDR_http" }}"
  cluster_addr  = "{{ env "NOMAD_ALLOC_ADDR_cluster" }}"
  tls_disable   = true
}

api_addr     = "http://{{ env "NOMAD_ALLOC_ADDR_http" }}"
cluster_addr = "http://{{ env "NOMAD_ALLOC_ADDR_cluster" }}"
EOT
      }

      resources {
        cpu    = 500
        memory = 512
      }
    }
  }

  group "vault-2" {
    shutdown_delay = "15s"

    network {
      mode = var.network_mode
      port "http" {
        to = 8200
      }
      port "cluster" {
        to = 8201
      }
    }

    volume "vault-data" {
      type      = "host"
      source    = "vault-2"
      read_only = false
    }

    service {
      name     = "vault-http"
      provider = "nomad"
      port     = "http"

      check {
        name     = "vault_http_probe"
        type     = "http"
        path     = "/v1/sys/health?standbyok=true&sealedcode=200&uninitcode=200"
        interval = "10s"
        timeout  = "2s"
      }
    }

    service {
      name     = "vault-cluster"
      provider = "nomad"
      port     = "cluster"
    }

    task "vault" {
      driver = "docker"

      config {
        image = "hashicorp/vault:2.1.0"
        ports = ["http", "cluster"]
        args  = ["server", "-config=${NOMAD_TASK_DIR}/vault.hcl"]
      }

      volume_mount {
        volume      = "vault-data"
        destination = "/vault/data"
      }

      template {
        destination = "${NOMAD_TASK_DIR}/vault.hcl"
        change_mode = "restart"
        splay       = "30s"

        data = <<-EOT
ui            = true
disable_mlock = true
log_level     = "info"

storage "raft" {
  path    = "/vault/data"
  node_id = "vault-2"

  {{- range nomadService "vault-http" }}
  retry_join {
    leader_api_addr = "http://{{ .Address }}:{{ .Port }}"
  }
  {{ end -}}
}

listener "tcp" {
  address       = "{{ env "NOMAD_ALLOC_ADDR_http" }}"
  cluster_addr  = "{{ env "NOMAD_ALLOC_ADDR_cluster" }}"
  tls_disable   = true
}

api_addr     = "http://{{ env "NOMAD_ALLOC_ADDR_http" }}"
cluster_addr = "http://{{ env "NOMAD_ALLOC_ADDR_cluster" }}"
EOT
      }

      resources {
        cpu    = 500
        memory = 512
      }
    }
  }

  group "vault-3" {
    shutdown_delay = "15s"

    network {
      mode = var.network_mode
      port "http" {
        to = 8200
      }
      port "cluster" {
        to = 8201
      }
    }

    volume "vault-data" {
      type      = "host"
      source    = "vault-3"
      read_only = false
    }

    service {
      name     = "vault-http"
      provider = "nomad"
      port     = "http"

      check {
        name     = "vault_http_probe"
        type     = "http"
        path     = "/v1/sys/health?standbyok=true&sealedcode=200&uninitcode=200"
        interval = "10s"
        timeout  = "2s"
      }
    }

    service {
      name     = "vault-cluster"
      provider = "nomad"
      port     = "cluster"
    }

    task "vault" {
      driver = "docker"

      config {
        image = "hashicorp/vault:2.1.0"
        ports = ["http", "cluster"]
        args  = ["server", "-config=${NOMAD_TASK_DIR}/vault.hcl"]
      }

      volume_mount {
        volume      = "vault-data"
        destination = "/vault/data"
      }

      template {
        destination = "${NOMAD_TASK_DIR}/vault.hcl"
        change_mode = "restart"
        splay       = "30s"

        data = <<-EOT
ui            = true
disable_mlock = true
log_level     = "info"

storage "raft" {
  path    = "/vault/data"
  node_id = "vault-3"

  {{   range nomadService "vault-http" }}
  retry_join {
    leader_api_addr = "http://{{ .Address }}:{{ .Port }}"
  }
  {{ end }}
}

listener "tcp" {
  address       = "{{ env "NOMAD_ALLOC_ADDR_http" }}"
  cluster_addr  = "{{ env "NOMAD_ALLOC_ADDR_cluster" }}"
  tls_disable   = true
}

api_addr     = "http://{{ env "NOMAD_ALLOC_ADDR_http" }}"
cluster_addr = "http://{{ env "NOMAD_ALLOC_ADDR_cluster" }}"
EOT
      }

      resources {
        cpu    = 500
        memory = 512
      }
    }
  }
}
