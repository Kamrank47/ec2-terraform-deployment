resource "aws_lambda_layer_version" "infra_base" {
  layer_name               = var.layer_name
  description              = var.description
  compatible_runtimes      = var.compatible_runtimes
  compatible_architectures = var.compatible_architectures
  license_info             = var.license_info

  # --- CRITICAL: Provide dummy code details for initial creation ---
  # These values will be ignored on subsequent applies due to ignore_changes.
  # We need *something* valid here for the first apply.
  # Using a small, empty zip file is a common technique.
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
    ]
  }
}