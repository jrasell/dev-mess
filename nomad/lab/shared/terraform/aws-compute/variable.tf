variable "component_name" {
  description = "The stack component name used for tagging."
  type        = string
}

variable "stack_name" {
  description = "The name to associate to this stack and used for tagging."
  type        = string
}

variable "stack_owner" {
  description = "An identifier for the owner, that can be useful for identification."
  type        = string
  default     = "jrasell"
}

variable "instance_count" {
  description = "The number of instances to start."
  type        = number
  default     = 1
}

variable "ami_id" {
  description = "The AMI to use for the instance."
  type        = string
  default     = "ami-03628db51da52eeaa"
}

variable "instance_type" {
  description = "The instance type to use for the instance."
  type        = string
  default     = "m5.xlarge"
}

variable "subnet_id" {
  description = "The VPC Subnet ID to launch in."
  type        = string
}

variable "user_data" {
  description = "User data to provide when launching the instance."
  type        = string
  default     = ""
}

variable "security_group_ids" {
  description = "List of security group IDs to associate with."
  type        = list(string)
}

variable "ssh_key_name" {
  description = "Key name of the Key Pair to use for the instance."
  type        = string
}

variable "ebs_block_devices" {
  description = ""
  type        = list(object({
    size   = number
    type   = string
    device = string
  }))
  default = []
}

variable "ansible_user" {
  description = "The user Ansible uses for connectivity."
  type        = string
  default     = "jrasell"
}

variable "ansible_group_name" {
  description = "The name of the Ansible group to associate all instances to."
  type        = string
  default     = "default"
}
