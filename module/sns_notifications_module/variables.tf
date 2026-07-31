variable "project_name" {
  type        = string
  description = "Name of the project"
}

variable "environment" {
  type        = string
  description = "Environment name"
}

variable "email_addresses" {
  type        = list(string)
  description = "List of email addresses to receive notifications"
}

variable "autoscaling_group_names" {
  type        = list(string)
  description = "List of Auto Scaling Group names to monitor"
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to resources"
  default     = {}
} 