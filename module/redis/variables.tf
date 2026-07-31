variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "allowed_security_groups" {
  type        = list(string)
  description = "List of security group IDs allowed to access the Redis cluster"
}

variable "node_type" {
  type    = string
  default = "cache.t3.micro"
}

variable "num_cache_nodes" {
  type    = number
  default = 1
}

variable "port" {
  type    = number
  default = 6379
}

variable "parameter_group_family" {
  type    = string
  default = "redis7"
}

variable "redis_parameters" {
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

variable "tags" {
  type    = map(string)
  default = {}
} 