variable "group_num" {
  type        = number
  default     = 10
  description = "The number of nodesim allocations to trigger; each allocation runs 100 client processes."
}

job "nomad-nodesim" {

  group "nomad-nodesim" {

    network {
      mode = "bridge"
    }

    count = var.group_num

    task "nomad-nodesim" {
      driver      = "docker"
      kill_signal = "SIGINT"

      action "drop-server-bound-traffic" {
        command = "/bin/bash"
        args    = [
          "-c",
          <<EOT
iptables -A OUTPUT -p tcp -m tcp -d 192.168.1.110/32 -j DROP
iptables -A OUTPUT -p tcp -m tcp -d 192.168.1.111/32 -j DROP
iptables -A OUTPUT -p tcp -m tcp -d 192.168.1.112/32 -j DROP
EOT
        ]
      }

      action "enable-server-bound-traffic" {
        command = "/bin/bash"
        args    = [
          "-c",
<<EOT
iptables -D OUTPUT -p tcp -m tcp -d 192.168.1.110/32 -j DROP
iptables -D OUTPUT -p tcp -m tcp -d 192.168.1.111/32 -j DROP
iptables -D OUTPUT -p tcp -m tcp -d 192.168.1.112/32 -j DROP
EOT
        ]
      }

      action "view-iptables-rules" {
        command = "iptables"
        args    = [
          "-L",
          "-v",
        ]
      }

      config {
        privileged = true
        image      = "jrasell/nomad-nodesim:latest"
        command    = "nomad-nodesim"
        args       = [
          "-config=${NOMAD_TASK_DIR}/config.hcl",
        ]
      }

      template {
        data        = file("./.tls/nomad-agent-ca.pem")
        destination = "${NOMAD_TASK_DIR}/ca.pem"
      }

      template {
        data        = file("./.tls/uk1-client-nomad-key.pem")
        destination = "${NOMAD_TASK_DIR}/uk1-client-nomad-key.pem"
      }

      template {
        data        = file("./.tls/uk1-client-nomad.pem")
        destination = "${NOMAD_TASK_DIR}/uk1-client-nomad.pem"
      }

      template {
        data = <<EOH
node_name_prefix = "uk1-{{ env "NOMAD_SHORT_ALLOC_ID" }}"
node_num         = 100
server_addr      = "192.168.1.110:4647"
work_dir         = "{{ env "NOMAD_TASK_DIR" }}"

node {
  region     = "uk1"
  datacenter = "kent-sim"

  options = {
    "fingerprint.denylist" = "env_aws,env_gce,env_azure,env_digitalocean"
  }
}
EOH

        change_mode = "restart"
        destination = "${NOMAD_TASK_DIR}/config.hcl"
      }

      env {
        NOMAD_CACERT      = "/local/ca.pem"
        NOMAD_CLIENT_KEY  = "/local/uk1-client-nomad-key.pem"
        NOMAD_CLIENT_CERT = "/local/uk1-client-nomad.pem"
      }

      resources {
        cpu    = 150
        memory = 256
      }
    }
  }
}