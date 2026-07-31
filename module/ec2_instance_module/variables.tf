variable "ami" {
  description = "AMI ID for the EC2 instance"
  type        = string
}

variable "instance_type" {
  description = "Instance type for the EC2 instance"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the EC2 instance will be launched"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID where the EC2 instance will be launched"
  type        = string
}

variable "key_name" {
  description = "EC2 key pair name (.pem file name)"
  type        = string
  default     = null
}

variable "enable_elastic_ip" {
  description = "Whether to assign an Elastic IP to the instance"
  type        = bool
  default     = false
}

variable "instance_name" {
  description = "Name of the EC2 instance"
  type        = string
}

variable "role_name" {
  description = "Name of the IAM role for the EC2 instance"
  type        = string
}

variable "managed_policy_arns" {
  description = "List of managed policy ARNs to attach to the EC2 role"
  type        = list(string)
  default     = [
    "arn:aws:iam::aws:policy/AmazonEC2FullAccess",
    "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess",
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
  ]
}

variable "security_group_rules" {
  description = "Security group rules for the EC2 instance"
  type = list(object({
    type        = string
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = optional(list(string))
    source_security_group_id = optional(string)
    description = string
  }))
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "root_volume_size" {
  description = "Size of the root volume in GB"
  type        = number
  default     = 30
}

variable "root_volume_type" {
  description = "Type of the root volume"
  type        = string
  default     = "gp3"
}

variable "user_data" {
  description = "User data script for the EC2 instance"
  type        = string
  default     = null
}
