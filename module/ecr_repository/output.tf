output "ECR_REPOSITORY_NAME_FOR_BE" {
  description = "The name of the ECR repository"
  value       = aws_ecr_repository.my_ecr_repo.name
}

output "ecr_repository_url" {
  description = "The URL of the ECR repository"
  value       = aws_ecr_repository.my_ecr_repo.repository_url
}