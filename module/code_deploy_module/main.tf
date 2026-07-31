# Create CodeDeploy Application
resource "aws_codedeploy_app" "code_pipeline_app" {
  name             = var.code_deploy_application_name
  compute_platform = "Server"
}

# Create IAM role for AWS CodeDeploy with S3 access
resource "aws_iam_role" "codedeploy_role" {
  name = var.code_deploy_role_name
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "codedeploy.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })
}

# Create custom policy for S3 access
resource "aws_iam_role_policy" "codedeploy_s3_policy" {
  name = "codedeploy-s3-policy"
  role = aws_iam_role.codedeploy_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:GetObjectVersion",
          "s3:ListBucket",
          "s3:GetBucketLocation",
          "s3:GetObjectMetadata"
        ]
        Resource = [
          "arn:aws:s3:::${var.artifacts_bucket}",
          "arn:aws:s3:::${var.artifacts_bucket}/*"
        ]
      }
    ]
  })
}

# Attach AWS managed CodeDeploy policy
resource "aws_iam_role_policy_attachment" "codedeploy_policy_attachment" {
  role       = aws_iam_role.codedeploy_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole"
}

# Create CodeDeploy Deployment Group
resource "aws_codedeploy_deployment_group" "codedeploy_group" {
  app_name               = aws_codedeploy_app.code_pipeline_app.name
  deployment_group_name  = "codedeploy-deployment-group"
  deployment_config_name = "CodeDeployDefault.AllAtOnce"
  service_role_arn       = aws_iam_role.codedeploy_role.arn
  autoscaling_groups     = [var.deployment_config.autoscaling_group_name]

  deployment_style {
    deployment_option = "WITHOUT_TRAFFIC_CONTROL"
    deployment_type   = "IN_PLACE"
  }

  load_balancer_info {
    target_group_info {
      name = var.target_group_name
    }
  }

  ec2_tag_set {
    ec2_tag_filter {
      key   = "Environment"
      type  = "KEY_AND_VALUE"
      value = var.tags["Environment"]
    }
  }
}

# CloudWatch Log Group for deployment logs
resource "aws_cloudwatch_log_group" "codedeploy_log_group" {
  name              = "/aws/codedeploy/${var.code_deploy_application_name}"
  retention_in_days = 30
  tags              = var.tags
}



