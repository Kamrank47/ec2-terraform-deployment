resource "aws_kms_key" "ssm" {
  description         = var.kms_key_description
  enable_key_rotation = false

  tags = var.tags
}

resource "aws_kms_alias" "ssm" {
  name          = "alias/${var.project_name}-${var.environment}-${var.module_name}-ssm-key"
  target_key_id = aws_kms_key.ssm.key_id
}

resource "aws_ssm_parameter" "parameters" {
  for_each = var.parameters

  name        = each.value.name
  description = each.value.description
  type        = each.value.type
  value       = each.value.value
  key_id      = each.value.type == "SecureString" ? aws_kms_key.ssm.key_id : null

  lifecycle {
    ignore_changes = [
      value, # Ignore changes to the value so you can update it manually
    ]
  }
  tags = var.tags
}