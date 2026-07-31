output "kms_key_arn" {
  value = aws_kms_key.ssm.arn
}

output "parameter_arns" {
  value = { for k, v in aws_ssm_parameter.parameters : k => v.arn }
}