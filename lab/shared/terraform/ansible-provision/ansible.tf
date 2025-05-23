resource null_resource "provisioner" {
  provisioner "local-exec" {
    command = "ansible-playbook -i  ${var.ansible_inventory_path} ${var.ansible_playbook_path}"
  }
}
