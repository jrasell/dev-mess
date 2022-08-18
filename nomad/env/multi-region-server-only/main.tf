provider "nomad" {
  address   = "http://${var.authoritative_region_ips[0]}:4646"
  region    = var.authoritative_region
  secret_id = var.nomad_root_token
}

module "shared" {
  source = "../modules/shared"

  ssh_ips              = concat(var.authoritative_region_ips, var.federated_region_ips)
  ssh_private_key_path = var.ssh_private_key_path
}

module "nomad-server-authoritative" {
  source     = "../modules/nomad-server"
  depends_on = [module.shared]

  region                   = var.authoritative_region
  authoritative_region     = var.authoritative_region
  server_ips               = var.authoritative_region_ips
  ssh_private_key_path     = var.ssh_private_key_path
  remote_nomad_file_path   = module.shared.remote_nomad_file_path
  remote_script_path       = module.shared.remote_script_path
}

module "nomad-bootstrap-authoritative" {
  source     = "../modules/nomad-bootstrap"
  depends_on = [module.nomad-server-authoritative]

  server_ip       = var.authoritative_region_ips[0]
  region          = var.authoritative_region
  bootstrap_token = var.nomad_root_token
}

module "nomad-server-eu-central-1" {
  source     = "../modules/nomad-server"
  depends_on = [module.shared, module.nomad-bootstrap-authoritative]

  region                   = var.federated_region
  authoritative_region     = var.authoritative_region
  replication_token        = var.nomad_root_token
  server_ips               = var.federated_region_ips
  server_join_ip           = "${var.authoritative_region_ips[0]}:4648"
  ssh_private_key_path     = var.ssh_private_key_path
  remote_nomad_file_path   = module.shared.remote_nomad_file_path
  remote_script_path       = module.shared.remote_script_path
}
