resource "aws_kms_key" "lambda_secrets" {
  description             = "KMS key for Lambda secrets encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  tags                    = var.tags
}

resource "aws_kms_alias" "lambda_secrets" {
  name          = "alias/${var.environment}/lambda-secrets"
  target_key_id = aws_kms_key.lambda_secrets.key_id
}

resource "aws_secretsmanager_secret" "lambda_secrets" {
  for_each = var.secrets

  name        = "${var.environment}/${each.value.name}"
  description = each.value.description
  kms_key_id  = aws_kms_key.lambda_secrets.arn
  tags        = var.tags
}

resource "aws_secretsmanager_secret_version" "lambda_secrets" {
  for_each = var.secrets

  secret_id     = aws_secretsmanager_secret.lambda_secrets[each.key].id
  secret_string = "{}" # Empty JSON object as placeholder

  lifecycle {
    ignore_changes = [
      secret_string
    ]
  }
}
