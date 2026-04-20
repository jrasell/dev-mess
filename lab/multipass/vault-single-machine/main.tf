module "vault_server" {
  source = "../../shared/terraform/multipass-compute"

  ansible_group_name   = "vault_server"
  instance_count       = 1
  instance_cpus        = 1
  instance_memory      = "1GiB"
  instance_name_prefix = "vault-server"
  instance_ssh_key     = file("~/.ssh/id_rsa.pub")
}

module "ansible_provision" {
  source     = "../../shared/terraform/ansible-provision"
  depends_on = [module.vault_server]

  ansible_inventory_path = abspath("./inventory.yaml")
  ansible_playbook_path  = abspath("./playbook_all.yaml")
}

output "msg" {
  value = <<EOH
After the first apply, you should run the following commands to prepare Vault
and you local envrionment:

  - ./scripts/init_unseal.sh --addr ${module.vault_server.instance_ips[0]}
  - export VAULT_TOKEN="$(jq -r .root_token generated_vault_init.json)"

SSH:       ssh ${module.vault_server.instance_ips[0]}
Vault UI:  http://${module.vault_server.instance_ips[0]}:8200
EOH
}

output "vault_server_address" {
  value = module.vault_server.instance_ips[0]
}
