resource "nomad_acl_policy" "dev-platform-read" {
  name       = "dev-platform-read"
  rules_hcl  = file("${path.module}/files/acl-policy-dev-platform-read.hcl")
  depends_on = [null_resource.bootstrap]
}

resource "nomad_acl_policy" "dev-platform-write" {
  name       = "dev-platform-write"
  rules_hcl  = file("${path.module}/files/acl-policy-dev-platform-write.hcl")
  depends_on = [null_resource.bootstrap]
}

resource "nomad_acl_policy" "dev-web-read" {
  name       = "dev-web-read"
  rules_hcl  = file("${path.module}/files/acl-policy-dev-web-read.hcl")
  depends_on = [null_resource.bootstrap]
}

resource "nomad_acl_policy" "dev-web-write" {
  name       = "dev-web-write"
  rules_hcl  = file("${path.module}/files/acl-policy-dev-web-write.hcl")
  depends_on = [null_resource.bootstrap]
}

resource "nomad_acl_policy" "general-read" {
  name       = "general-read"
  rules_hcl  = file("${path.module}/files/acl-policy-general-read.hcl")
  depends_on = [null_resource.bootstrap]
}

resource "nomad_acl_policy" "general-write" {
  name       = "general-write"
  rules_hcl  = file("${path.module}/files/acl-policy-general-write.hcl")
  depends_on = [null_resource.bootstrap]
}
