variable "environment" {
  type        = string
  description = "Environment name (e.g., dev, stage, prod)"
}

variable "project" {
  type        = string
  description = "Name of your project"
}

variable "allowed_repos" {
  type        = list(string)
  description = "List of GitHub repositories allowed to assume the role (format: repo:org/repo:*)"
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to resources"
  default     = {}
}

variable "create_oidc_provider" {
  description = "Whether to create the OIDC provider or use an existing one"
  type        = bool
  default     = false
}