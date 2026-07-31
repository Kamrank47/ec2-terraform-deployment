variable "SSH_ALLOWED_IP" {
  type        = string
  description = "IP address allowed for SSH (e.g., '1.2.3.4/32')"
  validation {
    condition     = var.SSH_ALLOWED_IP != "0.0.0.0/0"
    error_message = "SSH port must be specified and cannot be 0"
  }
}

variable "security_group_allowed_ports" {
  type        = list(number)
  description = "List of ports to allow in the security group"
  default     = []
}

variable "elb_security_group_id" {
  type        = string
  description = "Id of ELB security group"
  default     = ""
}

variable "VPC_ID" {
  description = "ID of the VPC"
  type        = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "security_group_rules" {
  type = object({
    ingress_rules = list(object({
      from_port        = number
      to_port          = number
      protocol         = string
      cidr_blocks      = optional(list(string))
      security_groups  = optional(list(string))
      description      = string
    }))
    egress_rules = list(object({
      from_port        = number
      to_port          = number
      protocol         = string
      cidr_blocks      = optional(list(string))
      security_groups  = optional(list(string))
      description      = string
    }))
  })
}