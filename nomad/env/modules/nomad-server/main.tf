data "template_file" "server_config_base" {
  template = file("${path.module}/templates/nomad_server_base.hcl.tpl")

  vars = {
    region               = var.region
    authoritative_region = var.authoritative_region
  }
}

data "template_file" "server_config_acl" {
  template = file("${path.module}/templates/nomad_server_acl.hcl.tpl")

  vars = {
    replication_token = var.replication_token
  }
}

resource "null_resource" "server_install" {
  depends_on = [null_resource.server_acl]

  triggers = {
    server_ips = join(",", var.server_ips)
  }

  count = length(var.server_ips)

  connection {
    type        = "ssh"
    user        = var.ssh_user
    port        = var.ssh_port
    host        = var.server_ips[count.index]
    private_key = file(var.ssh_private_key_path)
  }

  provisioner "file" {
    source      = "${path.module}/files/nomad.service"
    destination = "${var.remote_nomad_file_path}nomad.service"
  }

  provisioner "file" {
    content     = data.template_file.server_config_base.rendered
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

resource "null_resource" "server_acl" {

  triggers = {
    server_ips = join(",", var.server_ips)
  }

  count = var.replication_token != "" ? length(var.server_ips) : 0

  connection {
    type        = "ssh"
    user        = var.ssh_user
    port        = var.ssh_port
    host        = var.server_ips[count.index]
    private_key = file(var.ssh_private_key_path)
  }

  provisioner "file" {
    content     = data.template_file.server_config_acl.rendered
    destination = "${var.remote_nomad_file_path}/acl.hcl"
  }
}

resource "null_resource" "server_join" {
  depends_on = [null_resource.server_install]

  triggers = {
    server_ips = join(",", var.server_ips)
  }

  count = var.server_join_ip != "" ? length(var.server_ips) : 0

  connection {
    type        = "ssh"
    user        = var.ssh_user
    port        = var.ssh_port
    host        = var.server_ips[count.index]
    private_key = file(var.ssh_private_key_path)
  }

  provisioner "remote-exec" {
    inline = [
      "nomad server join ${var.server_join_ip}",
    ]
  }
}
