variable "ELB_PUBLIC_NAME" {
  type        = string
  description = "Public name of ELB"
  validation {
    condition     = can(regex("^([a-zA-Z0-9-]+)$", var.ELB_PUBLIC_NAME))
    error_message = "Invalid ELB public name. Only alphanumeric characters and hyphens are allowed."
  }
}


variable "VPC_ID" {
  type        = string
  description = "VPC ID used for loadbalancer ..."
}

variable "VPC_SUBNET_ID" {
  type        = list(string)
  description = "Subnets of VPC"
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "target_group_name" {
  description = "Name of the target group"
  type        = string
}

variable "elb_allowed_host" {
  description = "Allowed host header for ALB"
  type        = string
}