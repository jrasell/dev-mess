variable "local_path" {
  description = "The local path where TLS certificates and keys will be stored."
  type        = string
  default     = "./tls"
}

variable "ca_create" {
  description = "Whether to create a new CA certificate and key."
  type        = bool
  default     = false
}

variable "ca_subject" {
  description = "The subject information for the CA certificate."
  type = object({
    country             = string
    province            = string
    locality            = string
    common_name         = string
    organization        = string
    organizational_unit = string
  })
  default = ({
    country             = "GB"
    province            = "Kent"
    locality            = "Faversham"
    common_name         = "Nomad Agent CA"
    organization        = "HashiCorp"
    organizational_unit = "Nomad Engineering"
  })
}

variable "ca_validity_hours" {
  description = "The validity period of the CA certificate in hours."
  type        = number
  default     = 43800
}

variable "certificate" {
  description = "Details for the TLS certificate to be generated. If null, no certificate will be generated."
  type = object({
    name           = string
    dns_names      = list(string)
    ip_addresses   = list(string)
    validity_hours = number
    ca_cert_pem    = string
    ca_cert_key    = string
  })
  default = null
}
