name      = "vault-3"
type      = "host"
plugin_id = "mkdir"

capacity_min = "10G"
capacity_max = "20G"

capability {
  access_mode     = "single-node-reader-only"
  attachment_mode = "file-system"
}

capability {
  access_mode     = "single-node-writer"
  attachment_mode = "file-system"
}

parameters = {
  uid = 100
  gid = 1000
}
