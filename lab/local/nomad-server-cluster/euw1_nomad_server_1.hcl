data_dir   = "/tmp/nomad-server-cluster/euw1/server-1/"

log_level            = "DEBUG"
log_include_location = true
enable_debug         = true
region               = "euw1"
name                 = "server-1"

server {
  authoritative_region = "euw1"
  enabled              = true
  bootstrap_expect     = 3

  server_join {
    retry_join = ["127.0.0.1:5002", "127.0.0.1:6002"]
  }
}

acl {
  enabled = true
}
