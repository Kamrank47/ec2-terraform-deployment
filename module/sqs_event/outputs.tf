output "uuid" {
  description = "The UUID of the Lambda event source mapping"
  value       = aws_lambda_event_source_mapping.this.uuid
}

output "id" {
  description = "The ID of the Lambda event source mapping"
  value       = aws_lambda_event_source_mapping.this.id
}

output "function_arn" {
  description = "The ARN of the Lambda function the event source mapping is associated with"
  value       = aws_lambda_event_source_mapping.this.function_arn
}

output "event_source_arn" {
  description = "The ARN of the event source (SQS queue)"
  value       = aws_lambda_event_source_mapping.this.event_source_arn
}