output "load_balancer_name" {
  value = aws_lb.elastic_load_balancer.name
}

output "load_balancer_url" {
  value = aws_lb.elastic_load_balancer.dns_name
}

output "elb_security_group_id" {
  value = aws_security_group.elb_sg.id
}

# so that we can use this in the autoscaling group
output "target_group_arn" {
  description = "The ARN of the target group"
  value       = aws_lb_target_group.lb_target_group.arn
}

output "target_group_name" {
  description = "The name of the target group"
  value       = aws_lb_target_group.lb_target_group.name
}