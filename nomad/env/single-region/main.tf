provider "nomad" {
  address   = "http://${var.server_ips[0]}:4646"
  region    = var.region
  secret_id = var.nomad_root_token
}

module "shared" {
  source = "../modules/shared"

  ssh_ips              = concat(var.server_ips, var.client_ips)
  ssh_private_key_path = var.ssh_private_key_path
}

module "nomad-server" {
  source     = "../modules/nomad-server"
  depends_on = [module.shared]

  region                 = var.region
  authoritative_region   = var.region
  server_ips             = var.server_ips
  ssh_private_key_path   = var.ssh_private_key_path
  remote_nomad_file_path = module.shared.remote_nomad_file_path
  remote_script_path     = module.shared.remote_script_path
}

module "nomad-bootstrap" {
  source     = "../modules/nomad-bootstrap"
  depends_on = [module.nomad-server]

  server_ip       = var.server_ips[0]
  region          = var.region
  bootstrap_token = var.nomad_root_token
}

module "nomad-client" {
  source     = "../modules/nomad-client"
  depends_on = [module.shared, module.nomad-bootstrap]

  region                 = var.region
  server_ips             = var.server_ips
  client_ips             = var.client_ips
  ssh_private_key_path   = var.ssh_private_key_path
  remote_nomad_file_path = module.shared.remote_nomad_file_path
  remote_script_path     = module.shared.remote_script_path
}