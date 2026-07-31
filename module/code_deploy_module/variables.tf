variable "code_deploy_application_name" {
  description = "Name of the CodeDeploy application"
  type        = string
}

variable "code_deploy_role_name" {
  description = "Name of the IAM role for CodeDeploy"
  type        = string
}

variable "deployment_config" {
  description = "Configuration for deployment"
  type = object({
    autoscaling_group_name = string
  })
}

variable "tags" {
  description = "Tags to be applied to resources"
  type        = map(string)
}

variable "elb_name" {
  description = "Name of the Elastic Load Balancer"
  type        = string
}

variable "artifacts_bucket" {
  description = "Name of the S3 bucket for storing CodeDeploy artifacts"
  type        = string
}

variable "target_group_name" {
  description = "Name of the target group for the deployment group"
  type        = string
}