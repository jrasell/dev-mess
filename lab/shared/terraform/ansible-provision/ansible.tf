resource "null_resource" "provisioner" {
  provisioner "local-exec" {
    command = join(" ", compact([
      "ansible-playbook",
      "-i", var.ansible_inventory_path,
      length(var.ansible_extra_vars) > 0 ? format("-e %q", join(" ", var.ansible_extra_vars)) : "",
      var.ansible_playbook_path,
    ]))
  }
}
