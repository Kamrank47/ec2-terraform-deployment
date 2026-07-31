provider "aws" {
  region  = var.AWS_REGION
  profile = var.AWS_PROFILE != "" ? var.AWS_PROFILE : null // AWS CLI profile locally
}

locals {
  common_tags = {
    Project_Name = var.PROJECT_NAME
    Environment  = var.ENVIRONMENT_NAME
    Region       = var.AWS_REGION
  }
}

module "budget" {
  source = "./module/budget"
  
  create_budget    = var.budget_config.create_budget
  budget_name      = var.budget_config.budget_name
  limit_amount     = var.budget_config.limit_amount
  limit_unit       = var.budget_config.limit_unit
  time_unit        = var.budget_config.time_unit
  budget_type      = var.budget_config.budget_type
  
  notification = {
    comparison_operator        = var.budget_config.comparison_operator
    threshold                  = var.budget_config.threshold
    threshold_type            = var.budget_config.threshold_type
    notification_type          = var.budget_config.notification_type
    subscriber_email_addresses = var.budget_config.subscriber_email_addresses
  }
  
  tags = local.common_tags
}

module "parameter_store_for_lambda_functions" {
  source              = "./module/parameter_store"
  project_name        = var.PROJECT_NAME
  environment         = var.ENVIRONMENT_NAME
  kms_key_description = var.lambda_parameter_store_config.kms_key_description
  module_name         = "lambda"
  parameters = {
    for key, value in var.lambda_parameter_store_config.parameters : key => {
      name        = "/${var.PROJECT_NAME}/lambda/${var.ENVIRONMENT_NAME}/${value.name}"
      description = value.description
      type        = value.type
      value       = value.value
    }
  }
  tags = local.common_tags
}

module "parameter_store" {
  source              = "./module/parameter_store"
  project_name        = var.PROJECT_NAME
  environment         = var.ENVIRONMENT_NAME
  kms_key_description = var.parameter_store.kms_key_description
  module_name         = "be"
  parameters = {
    for key, value in var.parameter_store.parameters : key => {
      name        = "/${var.PROJECT_NAME}/backend/${var.ENVIRONMENT_NAME}/${value.name}"
      description = value.description
      type        = value.type
      value       = value.value
    }
  }
  tags = local.common_tags
}

module "parameter_store_value_for_ecr_repository" {
  source       = "./module/parameter_store"
  project_name = var.PROJECT_NAME
  environment  = var.ENVIRONMENT_NAME
  module_name  = "ecr"
  parameters = {
    ecr_repo = {
      name        = "/app/deployment/ecr_repository_name"
      description = "ECR repository URL for user data script service"
      type        = "String"
      value       = "${module.aws_ecr_repository_for_BE_module.ecr_repository_url}"
    }
  }
  tags = local.common_tags
}

module "aws_ecr_repository_for_BE_module" {
  source                     = "./module/ecr_repository"
  ECR_REPOSITORY_NAME_FOR_BE = var.ECR_REPOSITORY_NAME_FOR_BE
  tags                       = local.common_tags
}

module "vpc" {
  source = "./module/vpc"

  project_name        = var.PROJECT_NAME
  environment         = var.ENVIRONMENT_NAME
  vpc_cidr            = var.vpc.cidr
  availability_zones  = var.vpc.availability_zones
  public_subnet_cidrs = var.vpc.public_subnet_cidrs
  tags                = local.common_tags
}

module "load_balancer_module" {
  source            = "./module/aws_load_balancer_module"
  VPC_SUBNET_ID     = module.vpc.public_subnets
  VPC_ID            = module.vpc.vpc_id
  ELB_PUBLIC_NAME   = var.ELB_PUBLIC_NAME
  tags              = local.common_tags
  target_group_name = var.TARGET_GROUP_NAME
  elb_allowed_host  = var.elb_allowed_host
}

module "ec2_security_group_for_auto_scaling_module" {
  source                = "./module/aws_security_group_module"
  VPC_ID                = module.vpc.vpc_id
  elb_security_group_id = module.load_balancer_module.elb_security_group_id
  SSH_ALLOWED_IP        = var.SSH_ALLOWED_IP
  security_group_rules = {
    ingress_rules = [],
    egress_rules = [
      {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
        description = "Allow all outbound traffic"
      }
    ]
  }
  tags = local.common_tags
}

module "aws_key_pair_module" {
  source                     = "./module/aws_key_pair_module"
  EC2_INSTANCE_PEM_FILE_NAME = var.EC2_CONFIG.EC2_INSTANCE_PEM_FILE_NAME
  tags                       = local.common_tags
}

module "github_oidc" {
  source               = "./module/github_oidc"
  create_oidc_provider = var.github_oidc.create_oidc_provider
  environment          = var.ENVIRONMENT_NAME
  project              = var.PROJECT_NAME
  allowed_repos        = var.github_oidc.allowed_repos
  tags                 = local.common_tags
}

module "app_s3_assets" {
  source = "./module/s3"

  project_name      = var.PROJECT_NAME
  environment       = var.ENVIRONMENT_NAME
  bucket_name       = "${var.ENVIRONMENT_NAME}-${var.s3_public_bucket.bucket_name}"
  is_public         = var.s3_public_bucket.is_public
  enable_versioning = var.s3_public_bucket.enable_versioning
  cors_enabled      = var.s3_public_bucket.cors_enabled
  cors_rules        = var.s3_public_bucket.cors_rules
  tags              = local.common_tags
}

module "private_temporary_assets_bucket" {
  source = "./module/s3"

  project_name      = var.PROJECT_NAME
  environment       = var.ENVIRONMENT_NAME
  bucket_name       = "${var.ENVIRONMENT_NAME}-${var.private_temporary_assets_bucket.bucket_name}"
  is_public         = false
  enable_versioning = false
  cors_enabled      = true

  cors_rules = [{
    allowed_headers = ["*"]
    allowed_methods = ["PUT", "HEAD"]
    allowed_origins = [
      "http://localhost:3000",
      "https://dev.example.com"
    ]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }]
  lifecycle_rules = [{
    id      = "delete-old-assets"
    enabled = true
    expiration = {
      days = 3
    }
  }]
  tags = local.common_tags
}

module "private_assets_bucket" {
  source = "./module/s3"

  project_name      = var.PROJECT_NAME
  environment       = var.ENVIRONMENT_NAME
  bucket_name       = var.private_assets_bucket.bucket_name
  is_public         = false
  enable_versioning = true
  cors_enabled      = false

  notification_configuration = var.private_assets_bucket.lambda_function_name != null ? {
    lambda_function_name = var.private_assets_bucket.lambda_function_name
    # notification_configuration = {    
    #   lambda_function_name = module.lambda_functions["image_thumbnail"].function_name
    events = [
      "s3:ObjectCreated:Put",
      "s3:ObjectCreated:Post",
      "s3:ObjectCreated:Copy",
      "s3:ObjectCreated:CompleteMultipartUpload"
    ]
    filter_prefix = "Gifts/Image/"
  } : null

  # notification_lambda_function_name = module.lambda_functions["image_thumbnail"].function_name
  # notification_lambda_function_arn  = module.lambda_functions["image_thumbnail"].function_arn

  lifecycle_rules = [
    {
      id      = "transition-to-ia"
      enabled = true

      transition = [
        {
          days          = 30
          storage_class = "STANDARD_IA"
        }
      ]

      noncurrent_version_transition = [
        {
          days          = 30
          storage_class = "STANDARD_IA"
        }
      ]
    }
  ]

  tags = local.common_tags
}

module "ec2_auto_scaling_BE_module" {
  source                = "./module/auto_scaling_module"
  instance_type         = var.EC2_CONFIG.EC2_INSTANCE_TYPE
  ami                   = var.EC2_CONFIG.EC2_INSTANCE_AMI
  VPC_SUBNET_ID         = module.vpc.public_subnets
  elb_security_group_id = module.load_balancer_module.elb_security_group_id
  ec2_security_group_id = module.ec2_security_group_for_auto_scaling_module.ec2_security_group_id
  ec2_key_pair_name     = module.aws_key_pair_module.ec2_key_pair_name
  target_group_arn      = module.load_balancer_module.target_group_arn
  ASG_MIN_SIZE          = var.AUTO_SCALING_CONFIG.ASG_MIN_SIZE
  ASG_MAX_SIZE          = var.AUTO_SCALING_CONFIG.ASG_MAX_SIZE
  ASG_DESIRED_CAPACITY  = var.AUTO_SCALING_CONFIG.ASG_DESIRED_CAPACITY
  VPC_ID                = module.vpc.vpc_id
  ec2_role_name         = var.ec2_role_name
  tags                  = local.common_tags
  # sns_topic_arns        = [module.sns_notifications.asg_notifications_topic_arn]
  # Because the elastic IP of monitoring instance is used in the user data script
  depends_on = [module.ec2_monitoring_instance]
}

# Add security group rules after both security groups are created
resource "aws_security_group_rule" "monitoring_to_asg" {
  security_group_id        = module.ec2_security_group_for_auto_scaling_module.ec2_security_group_id
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = module.ec2_monitoring_instance.security_group_id
  description              = "Scrape Prometheus Matrices"
}

resource "aws_security_group_rule" "monitoring_to_asg_node_exporter" {
  security_group_id        = module.ec2_security_group_for_auto_scaling_module.ec2_security_group_id
  type                     = "ingress"
  from_port                = 9100
  to_port                  = 9100
  protocol                 = "tcp"
  source_security_group_id = module.ec2_monitoring_instance.security_group_id
  description              = "Scrape Node Exporter"
}

resource "aws_security_group_rule" "asg_to_monitoring_prometheus" {
  security_group_id        = module.ec2_monitoring_instance.security_group_id
  type                     = "ingress"
  from_port                = 9090
  to_port                  = 9090
  protocol                 = "tcp"
  source_security_group_id = module.ec2_security_group_for_auto_scaling_module.ec2_security_group_id
  description              = "Prometheus"
}

resource "aws_security_group_rule" "asg_to_monitoring_loki" {
  security_group_id        = module.ec2_monitoring_instance.security_group_id
  type                     = "ingress"
  from_port                = 3100
  to_port                  = 3100
  protocol                 = "tcp"
  source_security_group_id = module.ec2_security_group_for_auto_scaling_module.ec2_security_group_id
  description              = "Loki"
}

# Add HTTP access for monitoring instance
resource "aws_security_group_rule" "monitoring_http_access" {
  security_group_id = module.ec2_monitoring_instance.security_group_id
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "HTTP access for monitoring"
}

# Add HTTPS access for monitoring instance
resource "aws_security_group_rule" "monitoring_https_access" {
  security_group_id = module.ec2_monitoring_instance.security_group_id
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "HTTPS access for monitoring"
}

module "codedeploy_artifacts" {
  source = "./module/s3"

  project_name      = var.PROJECT_NAME
  environment       = var.ENVIRONMENT_NAME
  bucket_name       = "${var.ENVIRONMENT_NAME}-${var.codedeploy_artifacts_bucket.bucket_name}"
  is_public         = false
  enable_versioning = true
  cors_enabled      = false
  tags              = local.common_tags
}

module "code_deploy_BE_module" {
  source                       = "./module/code_deploy_module"
  code_deploy_application_name = var.BE_PIPELINE_CONFIG.CODE_DEPLOY_APPLICATION_NAME
  code_deploy_role_name        = var.BE_PIPELINE_CONFIG.CODE_DEPLOY_ROLE_NAME
  deployment_config = {
    autoscaling_group_name = module.ec2_auto_scaling_BE_module.autoscaling_group_name
  }
  target_group_name = module.load_balancer_module.target_group_name
  elb_name          = var.ELB_PUBLIC_NAME
  artifacts_bucket  = module.codedeploy_artifacts.bucket_name
  tags              = local.common_tags
}

module "sns_notifications" {
  source = "./module/sns_notifications_module"

  project_name            = var.PROJECT_NAME
  environment             = var.ENVIRONMENT_NAME
  email_addresses         = var.sns_notifications.email_addresses
  autoscaling_group_names = [module.ec2_auto_scaling_BE_module.autoscaling_group_name]
  tags                    = local.common_tags
}

module "transaction_processing_queue" {
  source                     = "./module/sqs"
  queue_name                 = "${var.ENVIRONMENT_NAME}-${var.transaction_processing_queue_config.queue_name}"
  dlq_name                   = "${var.ENVIRONMENT_NAME}-${var.transaction_processing_queue_config.dlq_name}"
  visibility_timeout_seconds = var.transaction_processing_queue_config.visibility_timeout_seconds
  message_retention_seconds  = var.transaction_processing_queue_config.message_retention_seconds
  max_receive_count          = var.transaction_processing_queue_config.max_receive_count
  fifo_queue                 = false
}

module "financial_ledger_queue" {
  source                     = "./module/sqs"
  queue_name                 = "${var.ENVIRONMENT_NAME}-${var.financial_ledger_queue_config.queue_name}"
  dlq_name                   = "${var.ENVIRONMENT_NAME}-${var.financial_ledger_queue_config.dlq_name}"
  visibility_timeout_seconds = var.financial_ledger_queue_config.visibility_timeout_seconds
  message_retention_seconds  = var.financial_ledger_queue_config.message_retention_seconds
  max_receive_count          = var.financial_ledger_queue_config.max_receive_count
  fifo_queue                 = false
}

module "baas_transaction_queue" {
  source                     = "./module/sqs"
  queue_name                 = "${var.ENVIRONMENT_NAME}-${var.baas_transaction_queue_config.queue_name}"
  dlq_name                   = "${var.ENVIRONMENT_NAME}-${var.baas_transaction_queue_config.dlq_name}"
  visibility_timeout_seconds = var.baas_transaction_queue_config.visibility_timeout_seconds
  message_retention_seconds  = var.baas_transaction_queue_config.message_retention_seconds
  max_receive_count          = var.baas_transaction_queue_config.max_receive_count
  fifo_queue                 = false
}

module "audit_tracking_queue" {
  source                     = "./module/sqs"
  queue_name                 = "${var.ENVIRONMENT_NAME}-${var.audit_tracking_queue_config.queue_name}"
  dlq_name                   = "${var.ENVIRONMENT_NAME}-${var.audit_tracking_queue_config.dlq_name}"
  visibility_timeout_seconds = var.audit_tracking_queue_config.visibility_timeout_seconds
  message_retention_seconds  = var.audit_tracking_queue_config.message_retention_seconds
  max_receive_count          = var.audit_tracking_queue_config.max_receive_count
  fifo_queue                 = false
}

module "notification_dispatch_queue" {
  source                     = "./module/sqs"
  queue_name                 = "${var.ENVIRONMENT_NAME}-${var.notification_dispatch_queue_config.queue_name}"
  dlq_name                   = "${var.ENVIRONMENT_NAME}-${var.notification_dispatch_queue_config.dlq_name}"
  visibility_timeout_seconds = var.notification_dispatch_queue_config.visibility_timeout_seconds
  message_retention_seconds  = var.notification_dispatch_queue_config.message_retention_seconds
  max_receive_count          = var.notification_dispatch_queue_config.max_receive_count
  fifo_queue                 = false
}

module "gift_processing_queue" {
  source                     = "./module/sqs"
  queue_name                 = "${var.ENVIRONMENT_NAME}-${var.gift_processing_queue_config.queue_name}"
  dlq_name                   = "${var.ENVIRONMENT_NAME}-${var.gift_processing_queue_config.dlq_name}"
  visibility_timeout_seconds = var.gift_processing_queue_config.visibility_timeout_seconds
  message_retention_seconds  = var.gift_processing_queue_config.message_retention_seconds
  max_receive_count          = var.gift_processing_queue_config.max_receive_count
  fifo_queue                 = false
}

module "external-events-queue" {
  source                     = "./module/sqs"
  queue_name                 = "${var.ENVIRONMENT_NAME}-${var.external-events-queue_config.queue_name}"
  dlq_name                   = "${var.ENVIRONMENT_NAME}-${var.external-events-queue_config.dlq_name}"
  visibility_timeout_seconds = var.external-events-queue_config.visibility_timeout_seconds
  message_retention_seconds  = var.external-events-queue_config.message_retention_seconds
  max_receive_count          = var.external-events-queue_config.max_receive_count
  fifo_queue                 = false
}

module "subscription-events-queue" {
  source                     = "./module/sqs"
  queue_name                 = "${var.ENVIRONMENT_NAME}-${var.subscription-events-queue_config.queue_name}"
  dlq_name                   = "${var.ENVIRONMENT_NAME}-${var.subscription-events-queue_config.dlq_name}"
  visibility_timeout_seconds = var.subscription-events-queue_config.visibility_timeout_seconds
  message_retention_seconds  = var.subscription-events-queue_config.message_retention_seconds
  max_receive_count          = var.subscription-events-queue_config.max_receive_count
  fifo_queue                 = false
}

module "reconciliation-discrepancy-queue" {
  source                     = "./module/sqs"
  queue_name                 = "${var.ENVIRONMENT_NAME}-${var.reconciliation-discrepancy-queue_config.queue_name}"
  dlq_name                   = "${var.ENVIRONMENT_NAME}-${var.reconciliation-discrepancy-queue_config.dlq_name}"
  visibility_timeout_seconds = var.reconciliation-discrepancy-queue_config.visibility_timeout_seconds
  message_retention_seconds  = var.reconciliation-discrepancy-queue_config.message_retention_seconds
  max_receive_count          = var.reconciliation-discrepancy-queue_config.max_receive_count
  fifo_queue                 = false
}

module "lambda_secrets" {
  source = "./module/secrets_manager"

  environment = var.ENVIRONMENT_NAME
  secrets = {
    for name, description in merge(
      var.lambda_secrets_config.webhook_dispatchers,
      var.lambda_secrets_config.message_consumers,
      var.lambda_secrets_config.backend
      ) : name => {
      name        = "lambda/${name}" # This creates paths like: dev/lambda/financial-webhook-dispatcher
      description = description
    }
  }
  tags = local.common_tags
}

module "app_logs_prod" {
  source = "./module/s3"

  project_name      = var.PROJECT_NAME
  environment       = var.ENVIRONMENT_NAME
  bucket_name       = var.s3_logs_bucket.bucket_name
  is_public         = false
  enable_versioning = false
  cors_enabled      = false
  tags              = local.common_tags
}

module "ec2_monitoring_instance" {
  source = "./module/ec2_instance_module"

  instance_name     = "${var.ENVIRONMENT_NAME}-${var.PROJECT_NAME}-monitoring-ec2"
  ami               = var.EC2_CUSTOM_CONFIG.ami_id
  instance_type     = var.EC2_CUSTOM_CONFIG.instance_type
  vpc_id            = module.vpc.vpc_id
  subnet_id         = module.vpc.public_subnets[0]
  key_name          = module.aws_key_pair_module.ec2_key_pair_name
  enable_elastic_ip = var.EC2_CUSTOM_CONFIG.enable_elastic_ip
  role_name         = "${var.ENVIRONMENT_NAME}-${var.PROJECT_NAME}-ec2-monitoring-role"
  user_data = templatefile("${path.module}/Utils/EC2_monitoring_user_data.sh", {
    monitoring_domain = var.monitoring_domain
    ENVIRONMENT = var.ENVIRONMENT_NAME
  })

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEC2FullAccess",
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",

  ]

  root_volume_size = var.EC2_CUSTOM_CONFIG.root_volume_size
  root_volume_type = var.EC2_CUSTOM_CONFIG.root_volume_type

  // add custom security group with ports here instead of getting from variable
  security_group_rules = [
    {
      type        = "ingress"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = [var.SSH_ALLOWED_IP]
      description = "SSH access"
    },
    {
      type        = "ingress"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "HTTP access"
    },
    {
      type        = "ingress"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "HTTPS access"
    },
    {
      type        = "ingress"
      from_port   = 3000
      to_port     = 3000
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "Grafana direct access"
    },
    {
      type        = "egress"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
      description = "Allow all outbound traffic"
    }
  ]

  # Disclaimer: Don't pass the common tags here. Otherwise autoscaling will try to send deployment here.
  tags = {
    Observability = "true"
    UserDataHash  = filebase64sha256("${path.module}/Utils/EC2_monitoring_user_data.sh")
    ForceRecreate = "v3"
  }

}

resource "aws_cloudwatch_metric_alarm" "transaction_processing_dlq_depth" {
  alarm_name          = "${var.ENVIRONMENT_NAME}-transaction-processing-dlq-depth"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = 60
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "DLQ has messages for transaction processing queue"
  dimensions = {
    QueueName = "${var.ENVIRONMENT_NAME}-${var.transaction_processing_queue_config.dlq_name}"
  }
  alarm_actions = [module.sns_notifications.asg_notifications_topic_arn]
}

resource "aws_cloudwatch_metric_alarm" "financial_ledger_dlq_depth" {
  alarm_name          = "${var.ENVIRONMENT_NAME}-financial-ledger-dlq-depth"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = 60
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "DLQ has messages for financial ledger queue"
  dimensions = {
    QueueName = "${var.ENVIRONMENT_NAME}-${var.financial_ledger_queue_config.dlq_name}"
  }
  alarm_actions = [module.sns_notifications.asg_notifications_topic_arn]
}

resource "aws_cloudwatch_metric_alarm" "baas_transaction_dlq_depth" {
  alarm_name          = "${var.ENVIRONMENT_NAME}-baas-transaction-dlq-depth"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = 60
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "DLQ has messages for baas transaction queue"
  dimensions = {
    QueueName = "${var.ENVIRONMENT_NAME}-${var.baas_transaction_queue_config.dlq_name}"
  }
  alarm_actions = [module.sns_notifications.asg_notifications_topic_arn]
}

resource "aws_cloudwatch_metric_alarm" "notification_dispatch_dlq_depth" {
  alarm_name          = "${var.ENVIRONMENT_NAME}-notification-dispatch-dlq-depth"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = 60
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "DLQ has messages for notification dispatch queue"
  dimensions = {
    QueueName = "${var.ENVIRONMENT_NAME}-${var.notification_dispatch_queue_config.dlq_name}"
  }
  alarm_actions = [module.sns_notifications.asg_notifications_topic_arn]
}

resource "aws_cloudwatch_metric_alarm" "audit_tracking_dlq_depth" {
  alarm_name          = "${var.ENVIRONMENT_NAME}-audit-tracking-dlq-depth"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = 60
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "DLQ has messages for audit tracking queue"
  dimensions = {
    QueueName = "${var.ENVIRONMENT_NAME}-${var.audit_tracking_queue_config.dlq_name}"
  }
  alarm_actions = [module.sns_notifications.asg_notifications_topic_arn]
}

resource "aws_cloudwatch_metric_alarm" "gift_processing_dlq_depth" {
  alarm_name          = "${var.ENVIRONMENT_NAME}-gift-processing-dlq-depth"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = 60
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "DLQ has messages for gift processing queue"
  dimensions = {
    QueueName = "${var.ENVIRONMENT_NAME}-${var.gift_processing_queue_config.dlq_name}"
  }
  alarm_actions = [module.sns_notifications.asg_notifications_topic_arn]
}

resource "aws_cloudwatch_metric_alarm" "external_events_dlq_depth" {
  alarm_name          = "${var.ENVIRONMENT_NAME}-external-events-dlq-depth"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = 60
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "DLQ has messages for external events queue"
  dimensions = {
    QueueName = "${var.ENVIRONMENT_NAME}-${var.external-events-queue_config.dlq_name}"
  }
  alarm_actions = [module.sns_notifications.asg_notifications_topic_arn]
}

resource "aws_cloudwatch_metric_alarm" "subscription_events_dlq_depth" {
  alarm_name          = "${var.ENVIRONMENT_NAME}-subscription-events-dlq-depth"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = 60
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "DLQ has messages for subscription events queue"
  dimensions = {
    QueueName = "${var.ENVIRONMENT_NAME}-${var.subscription-events-queue_config.dlq_name}"
  }
  alarm_actions = [module.sns_notifications.asg_notifications_topic_arn]
}
resource "aws_cloudwatch_metric_alarm" "reconciliation_discrepancy_depth" {
  alarm_name          = "${var.ENVIRONMENT_NAME}-reconciliation-discrepancy-depth"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = 60
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "Queue has messages for reconciliation discrepancy queue"
  dimensions = {
    QueueName = "${var.ENVIRONMENT_NAME}-${var.reconciliation-discrepancy-queue_config.queue_name}"
  }
  alarm_actions = [module.sns_notifications.asg_notifications_topic_arn]
}