variable "region" {
  description = "The Nomad region to use as the bootstrap target."
  type        = string
}

variable "server_ip" {
  description = "An IP of a Nomad server to connect to for bootstrapping."
  type        = string
}

variable "bootstrap_token" {
  description = "The UUID to use as the Nomad root token secret ID."
  type        = string
}
