variable "queue_name" {
  type = string
}

variable "dlq_name" {
  type = string
}

variable "message_retention_seconds" {
  type    = number
  default = 1209600
}

variable "max_receive_count" {
  type    = number
  default = 5
}

variable "fifo_queue" {
  type        = bool
  description = "Whether the queue should be FIFO"
  default     = false
}

variable "visibility_timeout_seconds" {
  type        = number
  description = "Visibility timeout for the SQS queue in seconds"
  default     = 70
}

