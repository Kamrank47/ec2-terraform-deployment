output "layer_arn" {
  description = "ARN of the Lambda layer version (base definition)"
  # Note: This ARN points to the initial version created by infra.
  # The deployment TF will create *new* versions. Use layer_name for referencing the layer itself.
  value = aws_lambda_layer_version.infra_base.arn
}

output "layer_version" {
  description = "Version number of the base Lambda layer definition"
  value       = aws_lambda_layer_version.infra_base.version
}

output "layer_name" {
  description = "Name of the Lambda layer"
  value       = aws_lambda_layer_version.infra_base.layer_name
}

output "compatible_runtimes" {
  description = "Compatible runtimes configured for the layer"
  value       = aws_lambda_layer_version.infra_base.compatible_runtimes
}