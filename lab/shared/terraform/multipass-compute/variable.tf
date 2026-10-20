variable "instance_image" {
  description = "The Multipass image to use."
  type        = string
  default     = "26.04"
}

variable "instance_name_prefix" {
  description = "The name prefix to use when filtering Multipass instances."
  type        = string
  default     = "instance"
}

variable "instance_count" {
  description = "The number of instances to start."
  type        = number
  default     = 1
}

variable "instance_cpus" {
  description = "The number of CPUs to assign the instance."
  type        = number
  default     = 4
}

variable "instance_memory" {
  description = "The memory to assign the instance."
  type        = string
  default     = "8GiB"
}

variable "instance_disk" {
  description = "The size of disk to allocate to the instances."
  type        = string
  default     = "20GiB"
}

variable "instance_ssh_key" {
  description = "The SSH key to add to the instance."
  type        = string
}

variable "instance_ssh_user" {
  description = "The SSH user to add the key from instance_ssh_key to."
  type        = string
  default     = "jrasell"
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

variable "instance_bridged" {
  description = "Whether to add a bridged network interface (--bridged)."
  type        = bool
  default     = false
}

variable "instance_networks" {
  description = "List of network specifications to add to the instance (e.g. ['name=en0,mode=auto'])."
  type        = list(string)
  default     = []
}

variable "instance_zone_map" {
  description = "Explicit mapping of instance index to zone (e.g. { \"0\" = \"zone1\", \"1\" = \"zone2\" })."
  type        = map(string)
  default     = {}
}

variable "instance_zones" {
  description = "A list of zones to randomly assign instances across."
  type        = list(string)
  default     = ["zone1", "zone2", "zone3"]
}

variable "instance_mounts" {
  description = "List of directory mounts in 'source:target' or 'source' format."
  type        = list(string)
  default     = []
}

variable "instance_timeout" {
  description = "Maximum time in seconds to wait for the launch command to complete."
  type        = number
  default     = 300
}
