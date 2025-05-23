name      = "nmd-srv-0"
type      = "host"
plugin_id = "mkdir"

capacity_min = "5G"
capacity_max = "10G"

capability {
  access_mode     = "single-node-reader-only"
  attachment_mode = "file-system"
}

capability {
  access_mode     = "single-node-writer"
  attachment_mode = "file-system"
}
