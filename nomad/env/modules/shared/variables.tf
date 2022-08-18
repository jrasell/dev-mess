variable "ssh_ips" {
  description = ""
  type        = list(string)
}

variable "ssh_user" {
  description = "The SSH user name to use when connecting to instances."
  type        = string
  default     = "vagrant"
}

variable "ssh_port" {
  description = "The SSH port to use when connecting to instances."
  type        = number
  default     = 22
}

variable "ssh_private_key_path" {
  description = "The SSH private key path to use when connecting to instances."
  type        = string
}
