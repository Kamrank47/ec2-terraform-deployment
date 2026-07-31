resource "aws_lambda_function" "this" {
  function_name = var.function_name
  handler       = var.handler
  runtime       = var.runtime
  role          = var.role_arn
  memory_size   = var.memory_size
  timeout       = var.timeout

  dynamic "vpc_config" {
    # Only include vpc_config block if subnet IDs are provided
    for_each = length(coalesce(var.vpc_subnet_ids, [])) > 0 ? [1] : []
    content {
      subnet_ids         = var.vpc_subnet_ids
      security_group_ids = var.vpc_security_group_ids
    }
  }

  environment {
    variables = var.environment_variables
  }

  # --- CRITICAL: Provide dummy code details for initial creation ---
  filename = "${path.module}/empty.zip" # Requires an empty zip file in the module dir

  # --- CRITICAL: Ignore changes made by the deployment process ---
  lifecycle {
    ignore_changes = [
      # Attributes managed by the deployment Terraform config
      filename,
      s3_bucket,
      s3_key,
      s3_object_version,
      source_code_hash,
      layers, # Deployment TF will provide specific layer *version* ARNs
      image_uri
    ]
  }

  # Use a static list for depends_on (empty if no external log group is referenced)
  depends_on = []

  tags = var.tags
}

# --- Optional: Function URL ---
resource "aws_lambda_function_url" "this" {
  count              = var.create_function_url ? 1 : 0
  function_name      = aws_lambda_function.this.function_name
  authorization_type = var.function_url_auth_type

  dynamic "cors" {
    for_each = var.function_url_cors != null ? [var.function_url_cors] : []
    content {
      allow_credentials = lookup(cors.value, "allow_credentials", null)
      allow_headers     = lookup(cors.value, "allow_headers", null)
      allow_methods     = lookup(cors.value, "allow_methods", null)
      allow_origins     = lookup(cors.value, "allow_origins", null)
      expose_headers    = lookup(cors.value, "expose_headers", null)
      max_age           = lookup(cors.value, "max_age", null)
    }
  }
}

# --- Optional: Function URL Permissions ---
# Automatically add permission if URL is created and auth is NONE
resource "aws_lambda_permission" "allow_public_url_access" {
  count = var.create_function_url && var.function_url_auth_type == "NONE" ? 1 : 0

  statement_id           = "FunctionURLAllowPublicAccess-${var.function_name}" # <-- Make statement_id unique per function
  action                 = "lambda:InvokeFunctionUrl"
  function_name          = aws_lambda_function.this.function_name
  principal              = "*"
  function_url_auth_type = "NONE"

  # Ensure the URL exists before adding permission
  depends_on = [aws_lambda_function_url.this]
}