output "asg_notifications_topic_arn" {
  description = "ARN of the SNS topic for ASG notifications"
  value       = aws_sns_topic.asg_notifications.arn
}

output "topic_name" {
  description = "Name of the SNS topic"
  value       = aws_sns_topic.asg_notifications.name
}