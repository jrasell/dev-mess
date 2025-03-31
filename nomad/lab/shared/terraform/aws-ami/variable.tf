variable "ami_owner" {
  description = "The AWS account ID of the AMI owner to search for."
  type        = string
  default     = "099720109477"
}

variable "ami_name_filter" {
  description = "The AMI name filter."
  type        = string
  default     = "ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"
}
