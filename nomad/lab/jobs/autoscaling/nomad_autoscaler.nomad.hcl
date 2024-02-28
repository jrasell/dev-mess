job "nomad-autoscaler" {
  type      = "service"
  namespace = "platform-autoscaling"

  group "nomad-autoscaler" {

    network {
      mode = "bridge"
      port "http" {}
    }

    task "nomad-autoscaler" {
      driver = "docker"

      config {
        image   = "hashicorp/nomad-autoscaler:0.4.2"
        command = "nomad-autoscaler"
        args = [
          "agent",
          "-config",
          "$${NOMAD_TASK_DIR}/config.hcl",
          "-http-bind-address",
          "0.0.0.0",
          "-http-bind-port",
          "$${NOMAD_PORT_http}",
        ]
      }

      identity {
        env = true
      }

      template {
        data        = file("./.tls/nomad-agent-ca.pem")
        destination = "${NOMAD_TASK_DIR}/ca.pem"
      }

      template {
        data = <<EOF
nomad {
  address   = "unix://{{ env "NOMAD_SECRETS_DIR" }}/api.sock"
  namespace = "*"
}

high_availability {
  enabled        = true
  lock_namespace = "platform-autoscaling"
}
EOF

        destination = "$${NOMAD_TASK_DIR}/config.hcl"
      }

      env {
        NOMAD_CACERT = "/local/ca.pem"
      }

      resources {
        cpu    = 150
        memory = 256
      }
    }
  }
}