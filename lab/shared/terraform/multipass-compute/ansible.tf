resource "ansible_group" "group" {
  name = var.ansible_group_name

  variables = {
    ansible_user = var.ansible_user
  }
}

resource "ansible_host" "host" {
  for_each = local.instance_names
  name     = each.value
  groups   = [ansible_group.group.name]

  variables = {
    ansible_host = data.multipass_instance.instance[each.key].ipv4
  }
}
