variable "id" {
  description = "The name of the vmagent Nomad job"
  type        = string
  default     = "vmagent-nomad"
}

variable "namespace" {
  description = "The Nomad namespace to deploy vmagent Nomad in"
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
}

job "vmagent-nomad" {
  id        = var.id
  name      = var.id
  namespace = var.namespace
  node_pool = var.node_pool

  group "vmagent" {

    network {
      mode = var.network_mode
      port "http" {}
    }

    service {
      address_mode = local.service_address_mode
      name         = "nomad-vmagent-http"
      port         = "http"
      provider     = "nomad"
    }

    task "discover" {
      lifecycle {
        hook    = "prestart"
        sidecar = true
      }

      driver = "docker"

      identity {
        env = true
      }

      template {
        data = <<-EOH
#!/bin/sh
set -eu

apk add --no-cache curl jq >/dev/null 2>&1

TARGETS_DIR="${NOMAD_ALLOC_DIR}/data/targets"
mkdir -p "$${TARGETS_DIR}"

while true; do
  # Clients: /v1/nodes
  CLIENT_JSON=$(curl -sf \
    --unix-socket "$${NOMAD_SECRETS_DIR}/api.sock" \
    -H "X-Nomad-Token: {{ env "NOMAD_TOKEN" }}" \
    "http://localhost/v1/nodes" || echo "[]")

  # Servers: /v1/agent/members
  SERVER_JSON=$(curl -sf \
    --unix-socket "$${NOMAD_SECRETS_DIR}/api.sock" \
    -H "X-Nomad-Token: {{ env "NOMAD_TOKEN" }}" \
    "http://localhost/v1/agent/members" || echo '{"Members":[]}')

  # Build file_sd JSON for clients.
  echo "$${CLIENT_JSON}" | jq '[
    .[] | select(.Status == "ready" and .Address != null) |
    {
      targets: [
        if (.HTTPAddr != null and .HTTPAddr != "") then .HTTPAddr
        else (.Address + ":4646") end
      ],
      labels: {
        node_name: .Name,
        datacenter: .Datacenter,
        node_pool: .NodePool
      }
    }
  ]' > "$${TARGETS_DIR}/clients.json.tmp" \
    && mv "$${TARGETS_DIR}/clients.json.tmp" "$${TARGETS_DIR}/clients.json"

  # Build file_sd JSON for servers.
  echo "$${SERVER_JSON}" | jq '[
    .Members[] | select(.Status == "alive") |
    {
      targets: ["\(.Addr):4646"],
      labels: {
        node_name: (.Name | split(".") | .[0])
      }
    }
  ]' > "$${TARGETS_DIR}/servers.json.tmp" \
    && mv "$${TARGETS_DIR}/servers.json.tmp" "$${TARGETS_DIR}/servers.json"

  echo "[$(date)] Discovered $(echo $${CLIENT_JSON} | jq '[.[] | select(.Status == "ready")] | length') clients, $(echo $${SERVER_JSON} | jq '.Members | [.[] | select(.Status == "alive")] | length') servers"

  sleep 30
done
EOH

        destination = "${NOMAD_TASK_DIR}/discover.sh"
        perms       = "0755"
      }

      config {
        image   = "alpine:3.19"
        command = "/bin/sh"
        args    = ["/local/discover.sh"]
      }

      resources {
        cpu    = 400
        memory = 512
      }
    }

    task "vmagent" {
      driver = "docker"

      template {
        data        = <<EOH
{{ with nomadVar "nomad/jobs/vmagent-nomad/vmagent" }}{{ .ca }}{{ end }}
EOH
        destination = "${NOMAD_TASK_DIR}/ca.pem"
      }

      identity {
        env = true
      }

      template {
        data = <<-EOH
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: nomad-servers
    scheme: https
    metrics_path: /v1/metrics
    params:
      format: [prometheus]
    {{ if ne (env "NOMAD_TOKEN") "" }}
    authorization:
      type: Bearer
      credentials: '{{ env "NOMAD_TOKEN" }}'
    {{ end }}
    tls_config:
      ca_file: /local/ca.pem
      insecure_skip_verify: false
    relabel_configs:
      - source_labels: [node_name]
        target_label: instance
    file_sd_configs:
      - files:
          - '{{ env "NOMAD_ALLOC_DIR" }}/data/targets/servers.json'

  - job_name: nomad-clients
    scheme: https
    metrics_path: /v1/metrics
    params:
      format: [prometheus]
    {{ if ne (env "NOMAD_TOKEN") "" }}
    authorization:
      type: Bearer
      credentials: '{{ env "NOMAD_TOKEN" }}'
    {{ end }}
    tls_config:
      ca_file: /local/ca.pem
      insecure_skip_verify: false
    relabel_configs:
      - source_labels: [node_name]
        target_label: instance
    file_sd_configs:
      - files:
          - '{{ env "NOMAD_ALLOC_DIR" }}/data/targets/clients.json'
EOH

        destination = "${NOMAD_TASK_DIR}/scrape.yml"
        change_mode = "noop"
      }

      template {
        data = <<-EOH
{{ range $i, $s := nomadService "victoria-metrics-http" }}{{ if eq $i 0 }}REMOTE_WRITE_URL=http://{{ .Address }}:{{ .Port }}/api/v1/write{{ end }}{{ end }}
EOH

        destination = "${NOMAD_TASK_DIR}/env"
        env         = true
      }

      config {
        image = "victoriametrics/vmagent:v1.144.0"
        args = [
          "-promscrape.config=/local/scrape.yml",
          "-remoteWrite.url=${REMOTE_WRITE_URL}",
          "-httpListenAddr=0.0.0.0:${NOMAD_PORT_http}",
          "-remoteWrite.tmpDataPath=${NOMAD_ALLOC_DIR}/data/vmagent-queue",
          "-promscrape.fileSDCheckInterval=15s",
        ]
      }

      resources {
        cpu    = 200
        memory = 128
      }
    }
  }
}
