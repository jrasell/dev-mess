data "template_file" "client_config_base" {
  template = file("${path.module}/templates/nomad_client_base.hcl.tpl")

  vars = {
    region     = var.region
    server_ips = jsonencode(var.server_ips)
  }
}

resource "null_resource" "client_install" {

  triggers = {
    server_ips = join(",", var.client_ips)
  }

  count = length(var.client_ips)

  connection {
    type        = "ssh"
    user        = var.ssh_user
    port        = var.ssh_port
    host        = var.client_ips[count.index]
    private_key = file(var.ssh_private_key_path)
  }

  provisioner "file" {
    source      = "${path.module}/files/nomad.service"
    destination = "${var.remote_nomad_file_path}nomad.service"
  }

  provisioner "file" {
    content     = data.template_file.client_config_base.rendered
    destination = "${var.remote_nomad_file_path}config.hcl"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo bash ${var.remote_script_path}install_machine.sh",
      "sudo bash ${var.remote_script_path}install_go.sh",
      "sudo bash ${var.remote_script_path}install_nomad.sh ${var.nomad_version}",
      "sudo bash ${var.remote_script_path}start_nomad.sh",
    ]
  }
}
