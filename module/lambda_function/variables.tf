# module/lambda_function/variables.tf

variable "function_name" {
  description = "Name for the Lambda function"
  type        = string
}

variable "handler" {
  description = "Lambda function handler"
  type        = string
}

variable "runtime" {
  description = "Lambda function runtime"
  type        = string
}

variable "role_arn" {
  description = "ARN of the IAM role for the Lambda function"
  type        = string
}

variable "memory_size" {
  description = "Memory size in MB"
  type        = number
  default     = 128
}

variable "timeout" {
  description = "Timeout in seconds"
  type        = number
  default     = 30
}

variable "layer_arns" {
  description = "List of Lambda Layer ARNs to attach (use layer names/base ARNs from infra layer module)"
  type        = list(string)
  default     = []
}

variable "environment_variables" {
  description = "Map of environment variables"
  type        = map(string)
  default     = {}
}

variable "vpc_subnet_ids" {
  description = "List of subnet IDs for VPC configuration"
  type        = list(string)
  default     = null # Set to null or empty list if not in VPC
}

variable "vpc_security_group_ids" {
  description = "List of security group IDs for VPC configuration"
  type        = list(string)
  default     = null # Set to null or empty list if not in VPC
}

variable "create_log_group" {
  description = "Set to false if a separate log group resource/module is used"
  type        = bool
  default     = true # Default to letting Lambda create it implicitly
}

variable "create_function_url" {
  description = "Set to true to create a Lambda Function URL"
  type        = bool
  default     = false
}

variable "function_url_auth_type" {
  description = "Authorization type for the Function URL (AWS_IAM or NONE)"
  type        = string
  default     = "AWS_IAM"
  validation {
    condition     = contains(["AWS_IAM", "NONE"], var.function_url_auth_type)
    error_message = "Authorization type must be AWS_IAM or NONE."
  }
}

variable "function_url_cors" {
  description = "CORS configuration for the Function URL"
  type = object({
    allow_credentials = optional(bool)
    allow_headers     = optional(list(string))
    allow_methods     = optional(list(string))
    allow_origins     = optional(list(string))
    expose_headers    = optional(list(string))
    max_age           = optional(number)
  })
  default = null
}

variable "tags" {
  description = "Tags to apply to the function"
  type        = map(string)
  default     = {}
}