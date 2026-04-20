resource "tls_private_key" "cert_key" {
  count       = var.certificate == null ? 0 : 1
  algorithm   = "ECDSA"
  ecdsa_curve = "P256"
}

resource "local_file" "cert_key" {
  count    = var.certificate == null ? 0 : 1
  content  = tls_private_key.cert_key[0].private_key_pem
  filename = "${var.local_path}/${var.certificate.name}-key.pem"
}

resource "tls_cert_request" "cert_csr" {
  count           = var.certificate == null ? 0 : 1
  private_key_pem = tls_private_key.cert_key[0].private_key_pem
  dns_names       = var.certificate.dns_names
  ip_addresses    = var.certificate.ip_addresses
}

resource "tls_locally_signed_cert" "cert" {
  count                 = var.certificate == null ? 0 : 1
  cert_request_pem      = tls_cert_request.cert_csr[0].cert_request_pem
  ca_cert_pem           = var.certificate.ca_cert_pem
  ca_private_key_pem    = var.certificate.ca_cert_key
  validity_period_hours = var.certificate.validity_hours

  allowed_uses = [
    "digital_signature",
    "key_encipherment",
    "server_auth",
    "client_auth",
  ]
}

resource "local_file" "cert" {
  count    = var.certificate == null ? 0 : 1
  content  = tls_locally_signed_cert.cert[0].cert_pem
  filename = "${var.local_path}/${var.certificate.name}.pem"
}
