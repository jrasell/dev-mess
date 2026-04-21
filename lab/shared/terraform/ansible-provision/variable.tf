variable "ansible_inventory_path" {
  description = "Path to the Ansible inventory to use."
  type        = string
}

variable "ansible_playbook_path" {
  description = "Path to the Ansible playbook to run."
  type        = string
}

variable "ansible_extra_vars" {
  description = "Extra variables to pass to Ansible."
  type        = list(string)
  default     = []
}
