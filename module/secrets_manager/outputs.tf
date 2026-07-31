output "secret_arns" {
  description = "Map of secret names to their ARNs"
  value = {
    for name, secret in aws_secretsmanager_secret.lambda_secrets : name => secret.arn
  }
}

output "kms_key_arn" {
  description = "ARN of the KMS key used for secrets encryption"
  value       = aws_kms_key.lambda_secrets.arn
}
