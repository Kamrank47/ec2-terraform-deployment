resource "aws_ecr_repository" "my_ecr_repo" {
  name         = var.ECR_REPOSITORY_NAME_FOR_BE
  force_delete = true
  tags         = var.tags
}

resource "aws_ecr_lifecycle_policy" "my_ecr_lifecycle_policy" {
  repository = aws_ecr_repository.my_ecr_repo.name

  policy = <<POLICY
{
  "rules": [
    {
      "rulePriority": 1,
      "description": "Retain only the latest 3 images",
      "selection": {
        "tagStatus": "any",
        "countType": "imageCountMoreThan",
        "countNumber": 3
      },
      "action": {
        "type": "expire"
      }
    }
  ]
}
POLICY
}
