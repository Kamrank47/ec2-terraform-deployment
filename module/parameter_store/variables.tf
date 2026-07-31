variable "project_name" {
  type        = string
  description = "Name of the project"
}

variable "environment" {
  type        = string
  description = "Environment name"
}

variable "kms_key_description" {
  type        = string
  default     = "Default KMS key for SSM parameters encryption"
  description = "Description for the KMS key"
}

variable "parameters" {
  type = map(object({
    name        = string
    description = string
    type        = string
    value       = string
  }))
  description = "Map of parameters to create in Parameter Store"
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to resources"
}

variable "module_name" {
  description = "Name of the module using this parameter store (e.g., 'ecr', 'rds')"
  type        = string
}