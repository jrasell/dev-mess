module "vault_server" {
  source = "../../shared/terraform/multipass-compute"

  ansible_group_name   = "vault_server"
  instance_count       = 3
  instance_cpus        = 1
  instance_image       = "trixie"
  instance_memory      = "1GiB"
  instance_name_prefix = "vault-server"
  instance_ssh_key     = file("~/.ssh/id_rsa.pub")
}

output "addresses" {
  description = "List of Vault server IP addresses."
  value       = module.vault_server.instance_ips
}
