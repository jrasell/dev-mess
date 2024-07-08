resource "ansible_group" "group" {
  name = var.ansible_group_name

  variables = {
    ansible_user = var.ansible_user
  }
}

resource "ansible_host" "host" {
  for_each = {for i in aws_instance.instance : i.tags.Name => i.public_ip}
  name     = each.key
  groups   = [ansible_group.group.name]

  variables = {
    ansible_host = each.value
  }
}
