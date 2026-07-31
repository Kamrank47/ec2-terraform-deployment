output "ecr_repository_url" {
  description = "The URL of the ECR repository"
  value       = module.aws_ecr_repository_for_BE_module.ecr_repository_url
}

output "github-oidc-role_arn-arn" {
  description = " ARN of the oidc role_arn with github"
  value       = module.github_oidc.role_arn
}

output "load_balancer_url" {
  description = " URL of the load balancer"
  value       = module.load_balancer_module.load_balancer_url
}

output "code_deploy_app_name" {
  description = "The name of the CodeDeploy application for BE application"
  value       = var.BE_PIPELINE_CONFIG.CODE_DEPLOY_APPLICATION_NAME
}

output "codedeploy_artifacts_bucket_name" {
  description = "Name of the S3 bucket used for CodeDeploy artifacts"
  value       = module.codedeploy_artifacts.bucket_name
}


# # --- Layer Outputs ---
# output "sharp_layer_name_infra" {
#   description = "Name of the provisioned Sharp layer"
#   value       = module.layer_sharp.layer_name
# }
# output "sharp_layer_arn_infra" {
#   description = "ARN of the provisioned Sharp layer definition"
#   value       = module.layer_sharp.layer_arn
# }
# output "sharp_layer_compatible_runtimes_infra" {
#   description = "Compatible runtimes for the Sharp layer"
#   value       = module.layer_sharp.compatible_runtimes # Assumes module outputs this
# }

# output "shared_layer_name_infra" {
#   description = "Name of the provisioned Shared layer"
#   value       = module.layer_shared.layer_name
# }
# output "shared_layer_arn_infra" {
#   description = "ARN of the provisioned Shared layer definition"
#   value       = module.layer_shared.layer_arn
# }
# output "shared_layer_compatible_runtimes_infra" {
#   description = "Compatible runtimes for the Shared layer"
#   value       = module.layer_shared.compatible_runtimes # Assumes module outputs this
# }

# # --- Function Outputs (Add for each function) ---
# output "image_thumbnail_function_name_infra" {
#   description = "Name of the provisioned image thumbnail function"
#   value       = module.lambda_functions["image_thumbnail"].function_name
# }
# output "image_thumbnail_function_arn_infra" {
#   description = "ARN of the provisioned image thumbnail function"
#   value       = module.lambda_functions["image_thumbnail"].function_arn
# }

# output "cloudflare_forward_function_name_infra" {
#   description = "Name of cloudflare forwarder (dev only)"
#   value       = try(module.lambda_functions["cloudflare_webhook_forward"].function_name, null)
# }
# output "cloudflare_forward_function_arn_infra" {
#   description = "ARN of cloudflare forwarder (dev only)"
#   value       = try(module.lambda_functions["cloudflare_webhook_forward"].function_arn, null)
# }
# output "cloudflare_forward_function_url_infra" {
#   description = "URL for cloudflare forwarder (dev only)"
#   value       = try(module.lambda_functions["cloudflare_webhook_forward"].function_url, null)
# }

# output "financial_dispatcher_function_name_infra" {
#   description = "Name of the financial dispatcher function"
#   value       = module.lambda_functions["financial_dispatcher"].function_name
# }
# output "financial_dispatcher_function_arn_infra" {
#   description = "ARN of the financial dispatcher function"
#   value       = module.lambda_functions["financial_dispatcher"].function_arn
# }
# output "financial_dispatcher_function_url_infra" {
#   description = "URL for financial webhook dispatcher"
#   value       = module.lambda_functions["financial_dispatcher"].function_url
# }

# output "sms_dispatcher_function_name_infra" {
#   description = "Name of the sms dispatcher function"
#   value       = module.lambda_functions["sms_dispatcher"].function_name
# }
# output "sms_dispatcher_function_arn_infra" {
#   description = "ARN of the sms dispatcher function"
#   value       = module.lambda_functions["sms_dispatcher"].function_arn
# }
# output "sms_dispatcher_function_url_infra" {
#   description = "URL for SMS provider webhook dispatcher"
#   value       = module.lambda_functions["sms_dispatcher"].function_url
# }

# output "financial_consumer_function_name_infra" {
#   description = "Name of the financial consumer function"
#   value       = module.lambda_functions["financial_consumer"].function_name
# }
# output "financial_consumer_function_arn_infra" {
#   description = "ARN of the financial consumer function"
#   value       = module.lambda_functions["financial_consumer"].function_arn
# }

# output "weavr_consumer_function_name_infra" {
#   description = "Name of the weavr consumer function"
#   value       = module.lambda_functions["weavr_consumer"].function_name
# }
# output "weavr_consumer_function_arn_infra" {
#   description = "ARN of the weavr consumer function"
#   value       = module.lambda_functions["weavr_consumer"].function_arn
# }

# output "audit_consumer_function_name_infra" {
#   description = "Name of the audit consumer function"
#   value       = module.lambda_functions["audit_consumer"].function_name
# }
# output "audit_consumer_function_arn_infra" {
#   description = "ARN of the audit consumer function"
#   value       = module.lambda_functions["audit_consumer"].function_arn
# }

# output "transaction_consumer_function_name_infra" {
#   description = "Name of the transaction consumer function"
#   value       = module.lambda_functions["transaction_consumer"].function_name
# }
# output "transaction_consumer_function_arn_infra" {
#   description = "ARN of the transaction consumer function"
#   value       = module.lambda_functions["transaction_consumer"].function_arn
# }