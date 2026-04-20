resource "tls_private_key" "ca_key" {
  count     = var.ca_create ? 1 : 0
  algorithm = "ECDSA"
}

resource "local_file" "ca_key" {
  count    = var.ca_create ? 1 : 0
  content  = tls_private_key.ca_key[0].private_key_pem
  filename = "${var.local_path}/ca-key.pem"
}

resource "tls_self_signed_cert" "ca_cert" {
  count           = var.ca_create ? 1 : 0
  private_key_pem = tls_private_key.ca_key[0].private_key_pem

  subject {
    country             = var.ca_subject.country
    province            = var.ca_subject.province
    locality            = var.ca_subject.locality
    common_name         = var.ca_subject.common_name
    organization        = var.ca_subject.organization
    organizational_unit = var.ca_subject.organizational_unit
  }

  is_ca_certificate     = true
  validity_period_hours = var.ca_validity_hours

  allowed_uses = [
    "digital_signature",
    "cert_signing",
    "crl_signing",
  ]
}

resource "local_file" "ca_cert" {
  count    = var.ca_create ? 1 : 0
  content  = tls_self_signed_cert.ca_cert[0].cert_pem
  filename = "${var.local_path}/ca.pem"
}
