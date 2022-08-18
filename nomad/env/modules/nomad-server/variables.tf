variable "nomad_version" {
  description = "The Nomad version to install. Can supply any version or dev for a development build."
  type        = string
  default     = "dev"
}

variable "region" {
  description = "The region identifier to use for the server instances."
  type        = string
}

variable "server_ips" {
  description = "The IP addresses of the instances that will be configured within this region."
  type        = list(string)
}

variable "authoritative_region" {
  description = "The authoritative region for this Nomad cluster. Set to var.region if a single region cluster."
  type        = string
}

variable "replication_token" {
  description = ""
  type        = string
  default     = ""
}

variable "server_join_ip" {
  description = "The IP and port of a server within another region to federate with. Empty value means no federation."
  type        = string
  default     = ""
}

variable "remote_script_path" {
  description = "The remote path where the shared scripts have been uploaded; passed via shared."
  type        = string
}

variable "remote_nomad_file_path" {
  description = "The remote path where the Nomad config files should be uploaded; passed via shared."
  type        = string
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
