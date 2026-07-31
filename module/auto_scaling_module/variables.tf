variable "ami" {
  description = "AMI ID for the EC2 instance"
}

variable "ASG_MIN_SIZE" {
  description = "Minimum size of the Auto Scaling group"
  type        = number
}

variable "ASG_MAX_SIZE" {
  description = "Maximum size of the Auto Scaling group"
  type        = number
}

variable "ASG_DESIRED_CAPACITY" {
  description = "Desired number of instances in the Auto Scaling group"
  type        = number
}

variable "ec2_key_pair_name" {
  type        = string
  description = "EC2 key pair name (.pem file name) "
}

variable "instance_type" {
  type        = string
  description = "Instance type for the EC2 instance"
}

variable "elb_security_group_id" {
  description = "ID of the ELB security group"
  type        = string
}

variable "ec2_security_group_id" {
  description = "ID of the EC2 security group"
  type        = string
}

variable "VPC_SUBNET_ID" {
  description = "List of subnet IDs for the Auto Scaling Group"
  type        = list(string)
}

variable "VPC_ID" {
  type        = string
  description = "VPC ID used for loadbalancer ..."
}

variable "ec2_role_permissions" {
  type        = list(string)
  description = "List of permissions to attach to the EC2 role"
  default = [
    "arn:aws:iam::aws:policy/AmazonS3FullAccess",
    "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess",
    "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess",
    "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess",
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    "arn:aws:iam::aws:policy/AmazonSQSFullAccess",
    "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
  ]
}

variable "target_group_arn" {
  description = "The ARN of the target group to add to the Auto Scaling group"
  type        = string
  default     = null
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "ec2_role_name" {
  description = "Name of the EC2 IAM role"
  type        = string
}

variable "sns_topic_arns" {
  description = "List of SNS topic ARNs for CloudWatch alarm notifications"
  type        = list(string)
  default     = []
}