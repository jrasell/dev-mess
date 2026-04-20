output "ca_cert_pem" {
  value = tls_self_signed_cert.ca_cert[0].cert_pem
}
