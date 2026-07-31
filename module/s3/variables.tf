variable "project_name" {
  type        = string
  description = "Name of the project"
}

variable "environment" {
  type        = string
  description = "Environment name"
}

variable "bucket_name" {
  type        = string
  description = "Name of the S3 bucket"
}

variable "is_public" {
  type        = bool
  description = "Whether the bucket should be public or private"
  default     = false
}

variable "enable_versioning" {
  type        = bool
  description = "Enable versioning for the bucket"
  default     = false
}

variable "cors_enabled" {
  type        = bool
  description = "Enable CORS for the bucket"
  default     = false
}

variable "cors_rules" {
  type = list(object({
    allowed_headers = list(string)
    allowed_methods = list(string)
    allowed_origins = list(string)
    expose_headers  = list(string)
    max_age_seconds = number
  }))
  description = "CORS rules for the bucket"
  default = [{
    allowed_headers = ["*"]
    allowed_methods = ["GET", "HEAD"]
    allowed_origins = ["*"]
    expose_headers  = []
    max_age_seconds = 3000
  }]
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to resources"
  default     = {}
}

variable "intelligent_tiering_enabled" {
  description = "Enable S3 Intelligent Tiering"
  type        = bool
  default     = false
}

variable "intelligent_tiering_config" {
  description = "Configuration for intelligent tiering"
  type = object({
    name                          = string
    status                        = string
    archive_access_tier_time      = number
    deep_archive_access_tier_time = number
  })
  default = null
}

variable "lifecycle_rules" {
  description = "List of lifecycle rules for the bucket"
  type = list(object({
    id      = string
    enabled = bool
    transition = optional(list(object({
      days          = number
      storage_class = string
    })))
    noncurrent_version_transition = optional(list(object({
      days          = number
      storage_class = string
    })))
    noncurrent_version_expiration = optional(object({
      days = number
    }))
    expiration = optional(object({
      days = number
    }))
  }))
  default = []
}

variable "notification_configuration" {
  description = "Configuration for S3 bucket notifications"
  type = object({
    lambda_function_name = string
    events               = list(string)
    filter_prefix        = string
  })
  default = null
}

# variable "notification_lambda_function_name" {
#   description = "Name of the Lambda function for S3 notification"
#   type        = string
#   default     = null
# }

# variable "notification_lambda_function_arn" {
#   description = "ARN of the Lambda function for S3 notification"
#   type        = string
#   default     = null
# }