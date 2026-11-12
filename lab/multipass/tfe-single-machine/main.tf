module "tfe" {
  source = "../../shared/terraform/multipass-compute"

  ansible_group_name   = "tfe"
  instance_count       = 1
  instance_cpus        = 4
  instance_image       = "trixie"
  instance_memory      = "6GiB"
  instance_name_prefix = "tfe"
  instance_ssh_key     = file("~/.ssh/id_rsa.pub")
}

module "ansible_provision" {
  source     = "../../shared/terraform/ansible-provision"
  depends_on = [module.tfe]

  ansible_inventory_path = abspath("./inventory.yaml")
  ansible_playbook_path  = abspath("./playbook_all.yaml")
}

data "external" "tfe_iact" {
  depends_on = [module.ansible_provision]

  program = [
    "sh", "-c",
    <<-EOT
      token=$(curl -ksf --retry 30 --retry-delay 2 --retry-all-errors \
        "https://${replace(module.tfe.instance_ips[0], ".", "-")}.jrasell.test/admin/retrieve-iact" || true)
      jq -n --arg token "$token" '{"token": $token}'
    EOT
  ]
}

output "msg" {
  value = <<EOH
SSH:          ssh ${module.tfe.instance_ips[0]}
TFE UI:       https://${replace(module.tfe.instance_ips[0], ".", "-")}.jrasell.test
RustFS UI:    http://${module.tfe.instance_ips[0]}:9001

Create the initial TFE admin user:
  curl -X POST \
    -H "Content-Type: application/json" \
    -d '{"username":"admin","email":"admin@email.com","password":"Password1!"}' \
    "https://${replace(module.tfe.instance_ips[0], ".", "-")}.jrasell.test/admin/initial-admin-user?token=${data.external.tfe_iact.result.token}"
EOH
}
