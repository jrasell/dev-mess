locals {
  workload_identity_path   = var.vault_kv_mount
  workload_identity_role   = "${var.vault_kv_mount}-workloads"
  workload_identity_policy = "${var.vault_kv_mount}-workloads"
}

resource "vault_jwt_auth_backend" "nomad" {
  default_role       = local.workload_identity_role
  jwks_url           = "${var.nomad_address}/.well-known/jwks.json"
  jwks_ca_pem        = var.nomad_jwks_ca_pem
  jwt_supported_algs = ["RS256"]
  path               = local.workload_identity_path
}

resource "vault_jwt_auth_backend_role" "nomad" {
  backend                 = vault_jwt_auth_backend.nomad.path
  bound_audiences         = ["vault.io"]
  role_name               = local.workload_identity_role
  role_type               = "jwt"
  token_period            = 1800
  token_policies          = [local.workload_identity_policy]
  token_type              = "service"
  user_claim              = "/nomad_job_id"
  user_claim_json_pointer = true

  claim_mappings = {
    nomad_namespace = "nomad_namespace"
    nomad_job_id    = "nomad_job_id"
    nomad_task      = "nomad_task"
  }
}

resource "vault_mount" "nomad" {
  path    = var.vault_kv_mount
  type    = "kv"
  options = { version = "2" }
}

resource "vault_policy" "nomad" {
  name = local.workload_identity_policy
  policy = templatefile("${path.module}/templates/vault-acl-jwt-policy-nomad-workloads.hcl.tpl", {
    AUTH_METHOD_ACCESSOR = vault_jwt_auth_backend.nomad.accessor
    MOUNT                = var.vault_kv_mount
  })
}
