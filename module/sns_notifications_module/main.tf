resource "aws_sns_topic" "asg_notifications" {
  name = "${var.project_name}-${var.environment}-asg-notifications"
  tags = var.tags
}

# Create email subscriptions for each email address
resource "aws_sns_topic_subscription" "email_subscriptions" {
  count     = length(var.email_addresses)
  topic_arn = aws_sns_topic.asg_notifications.arn
  protocol  = "email"
  endpoint  = var.email_addresses[count.index]
}

resource "aws_autoscaling_notification" "asg_notifications" {
  group_names = var.autoscaling_group_names

  notifications = [
    "autoscaling:EC2_INSTANCE_LAUNCH",
    "autoscaling:EC2_INSTANCE_TERMINATE",
    "autoscaling:EC2_INSTANCE_LAUNCH_ERROR",
    "autoscaling:EC2_INSTANCE_TERMINATE_ERROR",
  ]

  topic_arn = aws_sns_topic.asg_notifications.arn
}

# output "asg_notifications_topic_arn" {
#   value = aws_sns_topic.asg_notifications.arn
# }