variable "create_budget" {
  description = "Whether to create the budget"
  type        = bool
  default     = false
}

variable "budget_name" {
  description = "The name of the budget"
  type        = string
}

variable "budget_type" {
  description = "The type of budget (COST, USAGE, etc.)"
  type        = string
  default     = "COST"
}

variable "limit_amount" {
  description = "The budget limit amount"
  type        = string
}

variable "limit_unit" {
  description = "The unit of measurement for the budget limit"
  type        = string
  default     = "USD"
}

variable "time_unit" {
  description = "The time unit for the budget (MONTHLY, QUARTERLY, ANNUALLY)"
  type        = string
  default     = "MONTHLY"
}

variable "time_period_start" {
  description = "The start time for the budget period"
  type        = string
  default     = "2025-07-01_00:00"
}

variable "time_period_end" {
  description = "The end time for the budget period"
  type        = string
  default     = "2087-06-15_00:00"
}

variable "notification" {
  description = "Budget notification configuration"
  type = object({
    comparison_operator        = string
    threshold                  = number
    threshold_type            = string
    notification_type          = string
    subscriber_email_addresses = list(string)
  })
}

variable "tags" {
  description = "Tags to apply to the budget"
  type        = map(string)
  default     = {}
}
