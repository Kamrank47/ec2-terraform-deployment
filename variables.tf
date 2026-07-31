variable "AWS_REGION" {
  type        = string
  description = "AWS region where resources will be provisioned"
}

variable "AWS_PROFILE" {
  type        = string
  description = "AWS profile where resources will be provisioned"
}

variable "SSH_ALLOWED_IP" {
  type        = string
  description = "Allowed IP for SSH access"

  validation {
    condition     = can(regex("^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)(\\/([0-9]|[1-2][0-9]|3[0-2]))?$", var.SSH_ALLOWED_IP))
    error_message = "The SSH_ALLOWED_IP must be a valid IPv4 address in CIDR notation."
  }
}

variable "PROJECT_NAME" {
  type        = string
  description = "Project name"
}

variable "ENVIRONMENT_NAME" {
  type        = string
  description = "Environment name (e.g., dev, stage, prod)"

  validation {
    condition     = contains(["dev", "stage", "prod", "test"], var.ENVIRONMENT_NAME)
    error_message = "The ENVIRONMENT_NAME must be either dev, stage, prod, or test."
  }
}

variable "AUTO_SCALING_CONFIG" {
  description = "Configuration for autoscaling group"
  type = object({
    ASG_MIN_SIZE         = number
    ASG_MAX_SIZE         = number
    ASG_DESIRED_CAPACITY = number
  })
  default = {
    ASG_MIN_SIZE         = 1
    ASG_MAX_SIZE         = 1
    ASG_DESIRED_CAPACITY = 1
  }
}

variable "EC2_CONFIG" {
  description = "Configuration for EC2 instance"
  type = object({
    EC2_INSTANCE_TYPE          = string
    EC2_INSTANCE_AMI           = string
    EC2_INSTANCE_PEM_FILE_NAME = string
  })
}

variable "EC2_CUSTOM_CONFIG" {
  description = "Configuration for EC2 instance"
  type = object({
    instance_type          = string
    ami_id                 = string
    enable_elastic_ip      = bool
    root_volume_size       = number
    root_volume_type       = string
    security_group_rules   = list(object({
      type        = string
      from_port   = number
      to_port     = number
      protocol    = string
      cidr_blocks = optional(list(string))
      source_security_group_id = optional(string)
      description = string
    }))
  })
}



variable "BE_PIPELINE_CONFIG" {
  description = "Configuration for AWS CodePipeline"
  type = object({
    CODE_DEPLOY_APPLICATION_NAME = string
    CODE_DEPLOY_ROLE_NAME        = string
  })
}

variable "ELB_PUBLIC_NAME" {
  type        = string
  description = "Public name of the ELB"
}

variable "TARGET_GROUP_NAME" {
  type        = string
  description = "Public name of the ELB"
}

variable "ECR_REPOSITORY_NAME_FOR_BE" {
  type        = string
  description = "ECR Repository Name for storing the Docker images"
}

variable "github_oidc" {
  description = "GitHub OIDC configuration"
  type = object({
    create_oidc_provider = bool
    allowed_repos        = list(string)
  })
  default = {
    allowed_repos        = []
    create_oidc_provider = true
  }
}

variable "s3_public_bucket" {
  description = "S3 bucket configuration"
  type = object({
    bucket_name       = string
    is_public         = bool
    enable_versioning = bool
    cors_enabled      = bool
    cors_rules = list(object({
      allowed_headers = list(string)
      allowed_methods = list(string)
      allowed_origins = list(string)
      expose_headers  = list(string)
      max_age_seconds = number
    }))
  })
  default = {
    bucket_name       = ""
    is_public         = false
    enable_versioning = false
    cors_enabled      = false
    cors_rules = [{
      allowed_headers = ["*"]
      allowed_methods = ["GET", "HEAD"]
      allowed_origins = ["*"]
      expose_headers  = []
      max_age_seconds = 3000
    }]
  }
}

variable "parameter_store" {
  description = "Parameter Store configuration"
  type = object({
    kms_key_description = string
    parameters = map(object({
      name        = string
      description = string
      value       = string
      type        = string
    }))
  })
  default = {
    kms_key_description = "Default KMS key for SSM parameters encryption"
    parameters          = {}
  }
}

variable "vpc" {
  type = object({
    cidr                = string
    availability_zones  = list(string)
    public_subnet_cidrs = list(string)
  })
  description = "VPC configuration"
}

variable "codedeploy_artifacts_bucket" {
  description = "Configuration for CodeDeploy artifacts S3 bucket"
  type = object({
    bucket_name = string
  })
}

variable "private_temporary_assets_bucket" {
  description = "Configuration for private assets S3 bucket"
  type = object({
    bucket_name = string
  })
}

variable "s3_logs_bucket" {
  description = "Configuration for S3 logs bucket"
  type = object({
    bucket_name = string
  })
}

variable "private_assets_bucket" {
  description = "Configuration for private assets S3 bucket"
  type = object({
    bucket_name          = string
    lambda_function_name = optional(string)
  })
}

variable "redis_config" {
  description = "Redis cluster configuration"
  type = object({
    node_type              = string
    port                   = number
    parameter_group_family = string
    redis_parameters = list(object({
      name  = string
      value = string
    }))
  })
}

variable "sns_notifications" {
  description = "SNS notifications configuration"
  type = object({
    email_addresses = list(string)
  })
}

variable "elb_allowed_host" {
  description = "Allowed host header for ALB"
  type        = string
}

variable "ec2_role_name" {
  description = "EC2 role name"
  type        = string
}

variable "audit_tracking_queue_config" {
  description = "Configuration for the audit tracking queue and its associated DLQ"
  type = object({
    queue_name                 = string
    dlq_name                   = string
    max_receive_count          = number
    message_retention_seconds  = number
    visibility_timeout_seconds = number
  })
}

variable "transaction_processing_queue_config" {
  description = "Configuration for the transaction processing queue and its associated DLQ"
  type = object({
    queue_name                 = string
    dlq_name                   = string
    max_receive_count          = number
    message_retention_seconds  = number
    visibility_timeout_seconds = number
  })
}

variable "financial_ledger_queue_config" {
  description = "Configuration for the financial ledger queue and its associated DLQ"
  type = object({
    queue_name                 = string
    dlq_name                   = string
    max_receive_count          = number
    message_retention_seconds  = number
    visibility_timeout_seconds = number
  })
}

variable "baas_transaction_queue_config" {
  description = "Configuration for the BaaS transaction queue and its associated DLQ"
  type = object({
    queue_name                 = string
    dlq_name                   = string
    max_receive_count          = number
    message_retention_seconds  = number
    visibility_timeout_seconds = number
  })
}

variable "notification_dispatch_queue_config" {
  description = "Configuration for the notification dispatch queue and its associated DLQ"
  type = object({
    queue_name                 = string
    dlq_name                   = string
    max_receive_count          = number
    message_retention_seconds  = number
    visibility_timeout_seconds = number
  })
}
variable "gift_processing_queue_config" {
  description = "Configuration for the gift processing queue and its associated DLQ"
  type = object({
    queue_name                 = string
    dlq_name                   = string
    max_receive_count          = number
    message_retention_seconds  = number
    visibility_timeout_seconds = number
  })
}

variable "external-events-queue_config" {
  description = "Configuration for the external events queue and its associated DLQ"
  type = object({
    queue_name                 = string
    dlq_name                   = string
    max_receive_count          = number
    message_retention_seconds  = number
    visibility_timeout_seconds = number
  })
}

variable "subscription-events-queue_config" {
  description = "Configuration for the subscription events queue config and its associated DLQ"
  type = object({
    queue_name                 = string
    dlq_name                   = string
    max_receive_count          = number
    message_retention_seconds  = number
    visibility_timeout_seconds = number
  })
}

variable "reconciliation-discrepancy-queue_config" {
  description = "Configuration for the reconciliation discrepancy queue and its associated DLQ"
  type = object({
    queue_name                 = string
    dlq_name                   = string
    max_receive_count          = number
    message_retention_seconds  = number
    visibility_timeout_seconds = number
  })
}

variable "lambda_secrets_config" {
  description = "Configuration for Lambda function secrets"
  type = object({
    webhook_dispatchers = map(string)
    message_consumers   = map(string)
    backend             = map(string)
  })
}

variable "monitoring_domain" {
  description = "Domain for Grafana monitoring interface"
  type        = string
}

variable "budget_config" {
  description = "AWS Budget configuration"
  type = object({
    create_budget               = bool
    budget_name                 = string
    limit_amount               = string
    limit_unit                 = string
    time_unit                  = string
    budget_type                = string
    comparison_operator        = string
    threshold                  = number
    threshold_type             = string
    notification_type          = string
    subscriber_email_addresses = list(string)
  })
}

variable "lambda_parameter_store_config" {
  description = "Parameter Store configuration for lambda functions"
  type = object({
    kms_key_description = string
    parameters = map(object({
      name        = string
      description = string
      value       = string
      type        = string
    }))
  })
  default = {
    kms_key_description = "Store env variables for lambda functions"
    parameters          = {}
  }
}
/*
variable "lambda_event_source_config" {
  description = "Map of Lambda SQS event source configs: batch_size and batching window"
  type = map(object({
    batch_size                         = number
    maximum_batching_window_in_seconds = number
  }))
  default = {}
}

# --- General ---
variable "environment" {
  description = "Deployment environment (dev/prod)"
  type        = string
  validation {
    condition     = contains(["dev", "prod", "test"], var.environment)
    error_message = "Environment must be dev, prod, or test."
  }
}

variable "tags" {
  description = "Common tags for resources"
  type        = map(string)
  default = {
    ManagedBy = "Terraform-Infra"
  }
}

# --- S3 (External) ---
variable "image_processing_bucket_name" {
  description = "Name of the existing S3 bucket for image processing (from SAM BucketName param)"
  type        = string
}

# --- Base Names (Prefix added automatically) ---
variable "sharp_layer_base_name" {
  description = "Base name for the Sharp Lambda layer"
  type        = string
  default     = "sharp-layer"
}

variable "shared_layer_base_name" {
  description = "Base name for the Shared Lambda layer"
  type        = string
  default     = "shared-lambda-layer"
}

variable "lambda_functions" {
  description = "Map of Lambda function definitions. Key is logical name, value is an object with all properties."
  type = map(object({
    base_name              = string
    handler                = string
    runtime                = string
    memory_size            = number
    timeout                = number
    layers                 = list(string)
    environment            = map(string)
    create_function_url    = optional(bool, false)
    function_url_auth_type = optional(string, "NONE")
    function_url_cors = optional(object({
      allow_credentials = optional(bool)
      allow_headers     = optional(list(string))
      allow_methods     = optional(list(string))
      allow_origins     = optional(list(string))
      expose_headers    = optional(list(string))
      max_age           = optional(number)
    }), null)
  }))
}

variable "webhook_url" {
  description = "Webhook URL for cloudflare forwarder"
  type        = string
}

variable "weavr_api_url" {
  description = "Weavr API URL"
  type        = string
}

variable "log_retention_days" {
  description = "Default retention days for Lambda log groups"
  type        = number
  default     = 14
}

variable "image_thumbnail_function_base_name" {
  description = "Base name for the image thumbnail function"
  type        = string
  default     = "create-image-thumbnails"
}

variable "cloudflare_webhook_forward_function_base_name" {
  description = "Base name for the cloudflare webhook forwarder function"
  type        = string
  default     = "cloudflare-webhook-forward"
}

variable "financial_webhook_dispatcher_function_base_name" {
  description = "Base name for the financial webhook dispatcher function"
  type        = string
  default     = "financial-webhook-dispatcher"
}

variable "sms_provider_webhook_dispatcher_function_base_name" {
  description = "Base name for the sms provider webhook dispatcher function"
  type        = string
  default     = "sms-provider-webhook-dispatcher"
}

variable "financial_ledger_consumer_function_base_name" {
  description = "Base name for the financial ledger consumer function"
  type        = string
  default     = "financial-ledger-message-consumer"
}

variable "weavr_consumer_function_base_name" {
  description = "Base name for the weavr consumer function"
  type        = string
  default     = "weavr-message-consumer"
}

variable "audit_consumer_function_base_name" {
  description = "Base name for the audit consumer function"
  type        = string
  default     = "audit-message-consumer"
}

variable "transaction_consumer_function_base_name" {
  description = "Base name for the transaction consumer function"
  type        = string
  default     = "transaction-message-consumer"
}
variable "notification_consumer_function_base_name" {
  description = "Base name for the transaction consumer function"
  type        = string
  default     = "transaction-message-consumer"
}
*/