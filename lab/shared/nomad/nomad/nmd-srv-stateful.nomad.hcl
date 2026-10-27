variable "nomad_deployment_namespace" {
  type        = string
  description = "The Nomad namespace to deploy the job within."
  default     = "default"
}

variable "nomad_agent_region" {
  type        = string
  description = "The Nomad region identifier to configure the agent with."
  default     = "eghm1"
}

job "nmd-srv-stateful" {

  namespace = var.nomad_deployment_namespace

  group "srv-0" {

    network {
      mode = "bridge"

      port "http" {
        static = "5646"
      }
      port "rpc" {
        static = "5647"
      }
      port "serf" {
        static = "5648"
      }
    }

    service {
      name     = "${var.nomad-region}-nomad-server-http"
      port     = "http"
      provider = "nomad"

      check {
        name     = "alive"
        type     = "http"
        protocol = "http"
        method   = "GET"
        path     = "/v1/status/leader"
        interval = "10s"
        timeout  = "1s"
      }
    }

    service {
      name     = "${var.nomad-region}-nomad-server-rpc"
      port     = "rpc"
      provider = "nomad"
    }

    service {
      name     = "${var.nomad-region}-nomad-server-serf"
      port     = "serf"
      provider = "nomad"
    }

    volume "nomad-datadir" {
      type   = "host"
      source = "nmd-srv-0"
    }

    task "agent" {
      driver = "docker"

      meta {
        nomad_region = var.nomad-nomad_agent_region
      }

      config {
        image = "hashicorp/nomad:1.10.0-beta.1"
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
name         = "nmd-srv-0"
region       = "{{ env "NOMAD_META_nomad_region" }}"
enable_debug = true
log_level    = "DEBUG"

server {
  enabled          = true
  bootstrap_expect = 3

  server_join {
    retry_join = [
    {{- $regionName := env "NOMAD_META_nomad_region" }}{{ $serviceName := print $regionName "-nomad-server-serf" -}}
    {{ range nomadService $serviceName }}
      "{{ .Address}}:{{ .Port }}",{{- end }}
    ]
  }
}

ports {
  http = {{ env "NOMAD_PORT_http" }}
  rpc  = {{ env "NOMAD_PORT_rpc" }}
  serf = {{ env "NOMAD_PORT_serf" }}
}
EOH

        change_mode = "restart"
        destination = "${NOMAD_TASK_DIR}/config.hcl"
      }

      volume_mount {
        volume      = "nomad-datadir"
        destination = "${NOMAD_ALLOC_DIR}/nomad/"
      }

      resources {
        cpu    = 1000
        memory = 1024
      }
    }
  }
  group "srv-1" {

    network {
      mode = "bridge"

      port "http" {
        static = "5649"
      }
      port "rpc" {
        static = "5650"
      }
      port "serf" {
        static = "5651"
      }
    }

    service {
      name     = "${var.nomad-region}-nomad-server-http"
      port     = "http"
      provider = "nomad"

      check {
        name     = "alive"
        type     = "http"
        protocol = "http"
        method   = "GET"
        path     = "/v1/status/leader"
        interval = "10s"
        timeout  = "1s"
      }
    }

    service {
      name     = "${var.nomad-region}-nomad-server-rpc"
      port     = "rpc"
      provider = "nomad"
    }

    service {
      name     = "${var.nomad-region}-nomad-server-serf"
      port     = "serf"
      provider = "nomad"
    }

    volume "nomad-datadir" {
      type   = "host"
      source = "nmd-srv-1"
    }

    task "agent" {
      driver = "docker"

      meta {
        nomad_region = var.nomad-region
      }

      config {
        image = "hashicorp/nomad:1.10.0-beta.1"
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
name         = "nmd-srv-1"
region       = "{{ env "NOMAD_META_nomad_region" }}"
enable_debug = true
log_level    = "DEBUG"

server {
  enabled          = true
  bootstrap_expect = 3

  server_join {
    retry_join = [
    {{- $regionName := env "NOMAD_META_nomad_region" }}{{ $serviceName := print $regionName "-nomad-server-serf" -}}
    {{ range nomadService $serviceName }}
      "{{ .Address}}:{{ .Port }}",{{- end }}
    ]
  }
}

ports {
  http = {{ env "NOMAD_PORT_http" }}
  rpc  = {{ env "NOMAD_PORT_rpc" }}
  serf = {{ env "NOMAD_PORT_serf" }}
}
EOH

        change_mode = "restart"
        destination = "${NOMAD_TASK_DIR}/config.hcl"
      }

      volume_mount {
        volume      = "nomad-datadir"
        destination = "${NOMAD_ALLOC_DIR}/nomad/"
      }

      resources {
        cpu    = 1000
        memory = 1024
      }
    }
  }
  group "srv-2" {

    network {
      mode = "bridge"

      port "http" {
        static = "5652"
      }
      port "rpc" {
        static = "5653"
      }
      port "serf" {
        static = "5654"
      }
    }

    service {
      name     = "${var.nomad-region}-nomad-server-http"
      port     = "http"
      provider = "nomad"

      check {
        name     = "alive"
        type     = "http"
        protocol = "http"
        method   = "GET"
        path     = "/v1/status/leader"
        interval = "10s"
        timeout  = "1s"
      }
    }

    service {
      name     = "${var.nomad-region}-nomad-server-rpc"
      port     = "rpc"
      provider = "nomad"
    }

    service {
      name     = "${var.nomad-region}-nomad-server-serf"
      port     = "serf"
      provider = "nomad"
    }

    volume "nomad-datadir" {
      type   = "host"
      source = "nmd-srv-2"
    }

    task "agent" {
      driver = "docker"

      meta {
        nomad_region = var.nomad-region
      }

      config {
        image = "hashicorp/nomad:1.10.0-beta.1"
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
name         = "nmd-srv-2"
region       = "{{ env "NOMAD_META_nomad_region" }}"
enable_debug = true
log_level    = "DEBUG"

server {
  enabled          = true
  bootstrap_expect = 3

  server_join {
    retry_join = [
    {{- $regionName := env "NOMAD_META_nomad_region" }}{{ $serviceName := print $regionName "-nomad-server-serf" -}}
    {{ range nomadService $serviceName }}
      "{{ .Address}}:{{ .Port }}",{{- end }}
    ]
  }
}

ports {
  http = {{ env "NOMAD_PORT_http" }}
  rpc  = {{ env "NOMAD_PORT_rpc" }}
  serf = {{ env "NOMAD_PORT_serf" }}
}
EOH

        change_mode = "restart"
        destination = "${NOMAD_TASK_DIR}/config.hcl"
      }

      volume_mount {
        volume      = "nomad-datadir"
        destination = "${NOMAD_ALLOC_DIR}/nomad/"
      }

      resources {
        cpu    = 1000
        memory = 1024
      }
    }
  }
}
