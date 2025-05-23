variable "stack_name" {
  description = "The name to associate to this stack and used for tagging."
  type        = string
}

variable "stack_owner" {
  description = "An identifier for the owner, that can be useful for identification."
  type        = string
  default     = "jrasell"
}
