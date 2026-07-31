variable "environment" {
  description = "Environment name (dev/prod)"
  type        = string
}

variable "secrets" {
  description = "Map of secret configurations"
  type = map(object({
    name        = string
    description = string
  }))
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}
