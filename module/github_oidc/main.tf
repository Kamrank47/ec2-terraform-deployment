# First, try to get the existing provider
data "aws_iam_openid_connect_provider" "github" {
  count = var.create_oidc_provider == true ? 0 : 1
  url   = "https://token.actions.githubusercontent.com"
}

# Create the provider if it doesn't exist and create_oidc_provider is true
resource "aws_iam_openid_connect_provider" "github" {
  count = var.create_oidc_provider == true ? 1 : 0

  url = "https://token.actions.githubusercontent.com"

  client_id_list = ["sts.amazonaws.com"]

  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1"
  ]

  tags = var.tags

  lifecycle {
    ignore_changes  = [thumbprint_list]
    prevent_destroy = true
  }
}

# Use a local value to handle the provider ARN regardless of whether it exists or is created
locals {
  provider_arn = try(
    data.aws_iam_openid_connect_provider.github[0].arn,
    try(aws_iam_openid_connect_provider.github[0].arn, "")
  )
}

resource "aws_iam_role" "github_actions" {
  name = "${var.project}-${var.environment}-github-actions-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = local.provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = var.allowed_repos
          }
        }
      }
    ]
  })

  tags = var.tags
}

# Create policy for GitHub Actions role with necessary permissions
resource "aws_iam_policy" "github_actions_policy" {
  name_prefix = "${var.environment}-${var.project}-github-actions-policy"
  description = "Policy for GitHub Actions OIDC"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ECRFullAccess"
        Effect = "Allow"
        Action = [
          "ecr:*"
        ]
        Resource = "*"
      },
      {
        Sid    = "ParameterStoreAndSecretsFullAccess"
        Effect = "Allow"
        Action = [
          "ssm:*",
        ]
        Resource = "*"
      },
      {
        Sid    = "S3FullAccess"
        Effect = "Allow"
        Action = [
          "s3:*"
        ]
        Resource = [
          "arn:aws:s3:::*",
          "arn:aws:s3:::*/*"
        ]
      },
      {
        Sid    = "IAMPermissions"
        Effect = "Allow"
        Action = [
          "iam:*"
        ]
        Resource = "*"
      },
      {
        Sid    = "EC2Permissions"
        Effect = "Allow"
        Action = [
          "ec2:*"
        ]
        Resource = "*"
      },
      {
        Sid    = "CodeDeployAccess"
        Effect = "Allow"
        Action = [
          "codedeploy:*"
        ]
        Resource = "*"
      },
      {
        Sid    = "LoadBalancerAccess"
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:*"
        ]
        Resource = "*"
      },
      {
        Sid    = "AutoScalingAccess"
        Effect = "Allow"
        Action = [
          "autoscaling:*"
        ]
        Resource = "*"
      },
      {
        Sid    = "EC2KeyPairAccess"
        Effect = "Allow"
        Action = [
          "ec2:CreateKeyPair",
          "ec2:DeleteKeyPair",
          "ec2:ImportKeyPair",
          "ec2:DescribeKeyPairs"
        ]
        Resource = "*"
      },
      {
        Sid    = "KMSPermissions"
        Effect = "Allow"
        Action = [
          "kms:*",
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "sns:*"
        ]
        Resource = "*"
      },
      {
        Sid    = "LambdaAndSAMPermissions"
        Effect = "Allow"
        Action = [
          "lambda:*",
          "cloudformation:*",
          "apigateway:*",
          "logs:*",
          "iam:*"
        ]
        Resource = "*"
      },
      {
        Sid    = "SecretsManagerAccess"
        Effect = "Allow"
        Action = [
          "secretsmanager:*"
        ]
        Resource = "*"
      },
      {
        Sid    = "SQSAccess"
        Effect = "Allow"
        Action = [
          "sqs:*"
        ]
        Resource = "*"
      },
      {
        Sid    = "EventBridgeAccess"
        Effect = "Allow"
        Action = [
          "events:*"
        ]
        Resource = "*"
      },
      {
        Sid    = "BudgetAccess"
        Effect = "Allow"
        Action = [
          "budgets:*"
        ]
        Resource = "*"
      }
    ]
  })

  tags = var.tags

  lifecycle {
    create_before_destroy = true
  }
}

# Attach AWS managed policies to the GitHub role

resource "aws_iam_role_policy_attachment" "github_ecr_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess"
  role       = split("/", aws_iam_role.github_actions.arn)[1]
}

resource "aws_iam_role_policy_attachment" "github_vpc_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonVPCFullAccess"
  role       = split("/", aws_iam_role.github_actions.arn)[1]
}

resource "aws_iam_role_policy_attachment" "github_s3_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
  role       = split("/", aws_iam_role.github_actions.arn)[1]
}

resource "aws_iam_role_policy_attachment" "github_ssm_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMFullAccess"
  role       = split("/", aws_iam_role.github_actions.arn)[1]
}

resource "aws_iam_role_policy_attachment" "github_custom_policy" {
  policy_arn = aws_iam_policy.github_actions_policy.arn
  role       = split("/", aws_iam_role.github_actions.arn)[1]
}

resource "aws_iam_role_policy_attachment" "github_cloudwatch_policy" {
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
  role       = split("/", aws_iam_role.github_actions.arn)[1]
}

resource "aws_iam_role_policy_attachment" "github_cloudwatch_full_policy" {
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchFullAccess"
  role       = split("/", aws_iam_role.github_actions.arn)[1]
}

resource "aws_iam_role_policy_attachment" "github_codedeploy_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeDeployFullAccess"
  role       = split("/", aws_iam_role.github_actions.arn)[1]
}

resource "aws_iam_role_policy_attachment" "github_loadbalancer_policy" {
  policy_arn = "arn:aws:iam::aws:policy/ElasticLoadBalancingFullAccess"
  role       = split("/", aws_iam_role.github_actions.arn)[1]
}

resource "aws_iam_role_policy_attachment" "github_autoscaling_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AutoScalingFullAccess"
  role       = split("/", aws_iam_role.github_actions.arn)[1]
}