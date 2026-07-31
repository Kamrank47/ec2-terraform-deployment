output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.ec2_instance.id
}

output "instance_private_ip" {
  description = "Private IP address of the EC2 instance"
  value       = aws_instance.ec2_instance.private_ip
}

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance (if available)"
  value       = aws_instance.ec2_instance.public_ip
}

output "elastic_ip" {
  description = "Elastic IP address assigned to the instance (if enabled)"
  value       = var.enable_elastic_ip ? aws_eip.ec2_eip[0].public_ip : null
}

output "security_group_id" {
  description = "ID of the security group created for the EC2 instance"
  value       = aws_security_group.ec2_security_group.id
}

output "iam_role_arn" {
  description = "ARN of the IAM role created for the EC2 instance"
  value       = aws_iam_role.ec2_role.arn
}

output "iam_role_name" {
  description = "Name of the IAM role created for the EC2 instance"
  value       = aws_iam_role.ec2_role.name
}
