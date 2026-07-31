variable "function_name" {
  description = "Name or ARN of the Lambda function to trigger"
  type        = string
}

variable "event_source_arn" {
  description = "ARN of the SQS queue"
  type        = string
}

variable "enabled" {
  description = "Whether the event source mapping is active"
  type        = bool
  default     = true
}

variable "batch_size" {
  description = "Maximum number of items to retrieve in a single batch"
  type        = number
  default     = 10
}

variable "maximum_batching_window_in_seconds" {
  description = "Maximum amount of time to gather records before invoking the function"
  type        = number
  default     = null # Default behavior (no batching window)
}

variable "function_response_types" {
  description = "List of response types for partial batch failures (e.g., [\"ReportBatchItemFailures\"])"
  type        = list(string)
  default     = null
}

variable "filter_criteria" {
  description = "Filter criteria for the event source mapping"
  type = object({
    filters = list(object({
      pattern = string
    }))
  })
  default = null
}