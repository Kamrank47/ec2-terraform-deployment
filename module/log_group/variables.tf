variable "log_group_name" {
  description = "Name of the CloudWatch log group"
  type        = string
}

variable "retention_in_days" {
  description = "Log retention in days"
  type        = number
}

variable "kms_key_id" {
  description = "KMS key ID for encrypting log group (optional)"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to the log group"
  type        = map(string)
  default     = {}
}