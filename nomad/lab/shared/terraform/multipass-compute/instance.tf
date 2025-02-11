resource "local_file" "cloudinit" {
  content  = templatefile("${path.module}/files/cloudinit.yaml.tpl", {
    username = var.instance_ssh_user
    ssh_key  = var.instance_ssh_key
  })
  filename = "${path.module}/generated_cloudinit.yaml"
}

resource "multipass_instance" "instance" {
  count          = var.instance_count
  depends_on     = [local_file.cloudinit]
  name           = "${var.instance_name_prefix}-${count.index}"
  cpus           = var.instance_cpus
  memory         = var.instance_memory
  disk           = var.instance_disk
  image          = "lts"
  cloudinit_file = "${path.module}/generated_cloudinit.yaml"
}

data "multipass_instance" "instance" {
  depends_on = [multipass_instance.instance]
  count      = var.instance_count
  name       = "${var.instance_name_prefix}-${count.index}"
}
