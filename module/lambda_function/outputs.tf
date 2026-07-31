output "function_arn" {
  description = "ARN of the Lambda function"
  value       = aws_lambda_function.this.arn
}

output "function_name" {
  description = "Name of the Lambda function"
  value       = aws_lambda_function.this.function_name
}

output "function_invoke_arn" {
  description = "Invoke ARN of the Lambda function"
  value       = aws_lambda_function.this.invoke_arn
}

output "function_url" {
  description = "The generated Lambda Function URL (if created)"
  value       = try(aws_lambda_function_url.this[0].function_url, null)
}

output "function_url_id" {
  description = "The ID of the Lambda Function URL resource (if created)"
  value       = try(aws_lambda_function_url.this[0].id, null)
}