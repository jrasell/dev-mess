job "coredns" {
  datacenters = ["dc1"]
  type        = "system"

  group "coredns" {
    network {
      mode = "host"

      port "dns" {
        static = 1053
      }
    }

    task "coredns" {
      driver = "docker"

      config {
        image = "coredns/coredns:1.14.0"
        ports = ["dns"]
        args  = [
          "-conf",
          "/secrets/coredns/Corefile",
          "-dns.port",
          "1053",
        ]
      }

      identity {
        env = true
      }

      template {
        data = <<EOF
. {
  forward . 8.8.8.8 8.8.4.4 1.1.1.1
}

nomad. {
    nomad {
      address unix:///secrets/api.sock
    }

    cache 30
}
EOF

        destination   = "secrets/coredns/Corefile"
        change_mode   = "signal"
        change_signal = "SIGHUP"
      }

      resources {
        cpu    = 100
        memory = 128
      }

      service {
        name     = "coredns"
        port     = "dns"
        provider = "nomad"
      }
    }
  }
}
