job "nginx" {
  group "nginx" {

    network {
      mode = "bridge"
      port "http" {}
    }

    task "server" {

      template {
        data = <<EOF
user                            root;
worker_processes                auto;

error_log                       /var/log/nginx/error.log warn;

events {
    worker_connections          1024;
}

http {
    include                     /etc/nginx/mime.types;
    default_type                application/octet-stream;
    sendfile                    off;
    access_log                  off;
    keepalive_timeout           3000;
    server {
        listen                  {{ env "NOMAD_PORT_http" }};
        root                    /usr/share/nginx/html;
        index                   index.html;
        server_name             localhost;
        client_max_body_size    16m;
    }
}
EOF
        destination   = "local/nginx.conf"
        change_mode   = "signal"
        change_signal = "SIGHUP"
      }


      driver = "docker"
      config {
        image = "nginx:1.27.3"
        ports = ["http"]
        volumes = [
          "local/nginx.conf:/etc/nginx/nginx.conf",
        ]
      }

      resources {
        memory = 128
        cpu    = 100
      }
    }
  }
}
