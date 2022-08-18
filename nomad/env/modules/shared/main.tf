resource "null_resource" "script_upload" {

  triggers = {
    server_ips = join(",", var.ssh_ips)
  }

  count = length(var.ssh_ips)

  connection {
    type        = "ssh"
    user        = var.ssh_user
    port        = var.ssh_port
    host        = var.ssh_ips[count.index]
    private_key = file(var.ssh_private_key_path)
  }

  provisioner "file" {
    source      = "${path.module}/scripts"
    destination = "/donkey/scripts"
  }

  provisioner "remote-exec" {
    inline = [
      "mkdir -p /donkey/nomad",
    ]
  }
}
