resource "random_id" "instance_suffix" {
  count       = var.instance_count
  byte_length = 4

  keepers = {
    prefix = var.instance_name_prefix
  }
}

locals {
  instance_names = { for idx, id in random_id.instance_suffix : idx => "${var.instance_name_prefix}-${id.hex}" }
}

resource "local_file" "cloudinit" {
  content = templatefile("${path.module}/files/cloudinit.yaml.tpl", {
    username = var.instance_ssh_user
    ssh_key  = var.instance_ssh_key
  })
  filename = "${path.module}/generated_cloudinit.yaml"
}

resource "multipass_instance" "instance" {
  for_each       = local.instance_names
  depends_on     = [local_file.cloudinit]
  name           = each.value
  cpus           = var.instance_cpus
  memory         = var.instance_memory
  disk           = var.instance_disk
  image          = var.instance_image
  cloudinit_file = "${path.module}/generated_cloudinit.yaml"
}

data "multipass_instance" "instance" {
  for_each   = multipass_instance.instance
  depends_on = [multipass_instance.instance]
  name       = each.value.name
}
