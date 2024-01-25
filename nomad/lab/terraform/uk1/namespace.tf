locals {
  namespaces = [
    "platform-ingress",
    "platform-monitoring",
    "platform-testing",
  ]
}

resource "nomad_namespace" "namespace" {
  count = length(local.namespaces)
  name  = local.namespaces[count.index]
}
