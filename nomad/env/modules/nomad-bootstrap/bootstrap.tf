resource "null_resource" "bootstrap" {

  triggers = {
    server_ip = var.server_ip
  }

  provisioner "local-exec" {
    command = "echo ${var.bootstrap_token} > .nomad_root_token"
  }

  provisioner "local-exec" {
    command = "nomad acl bootstrap -address=http://${var.server_ip}:4646 .nomad_root_token"
  }
}
