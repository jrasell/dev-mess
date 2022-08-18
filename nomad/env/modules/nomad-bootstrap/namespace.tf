resource "nomad_namespace" "dev-platform" {
  name       = "dev-platform"
  depends_on = [null_resource.bootstrap]
}

resource "nomad_namespace" "dev-web" {
  name       = "dev-web"
  depends_on = [null_resource.bootstrap]
}
