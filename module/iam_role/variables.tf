# module/iam_role/variables.tf

variable "role_name" {
  description = "Name for the IAM role"
  type        = string
}

variable "assume_role_principal" {
  description = "Service principal that can assume this role (e.g., lambda.amazonaws.com)"
  type        = string
}

variable "managed_policy_arns" {
  description = "List of managed policy ARNs to attach"
  type        = list(string)
  default     = []
}

variable "policy_statements" {
  description = "List of inline policy statements"
  type = list(object({
    sid       = optional(string)
    actions   = list(string)
    effect    = optional(string, "Allow")
    resources = list(string)
    condition = optional(list(object({
      test     = string
      variable = string
      values   = list(string)
    })), [])
  }))
  default = []
}

variable "tags" {
  description = "Tags to apply to the role"
  type        = map(string)
  default     = {}
}