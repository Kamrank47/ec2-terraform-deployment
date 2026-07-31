resource "aws_s3_bucket" "this" {
  bucket = var.bucket_name
  tags   = var.tags
}

# Bucket versioning
resource "aws_s3_bucket_versioning" "this" {
  count  = var.enable_versioning ? 1 : 0
  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Public access block configuration
resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = var.is_public ? false : true
  block_public_policy     = var.is_public ? false : true
  ignore_public_acls      = var.is_public ? false : true
  restrict_public_buckets = var.is_public ? false : true
}

# Bucket policy for public access
resource "aws_s3_bucket_policy" "public_read" {
  count  = var.is_public ? 1 : 0
  bucket = aws_s3_bucket.this.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.this.arn}/*"
      },
    ]
  })

  # Ensure the public access block is configured before applying the policy
  depends_on = [aws_s3_bucket_public_access_block.this]
}

# CORS configuration
resource "aws_s3_bucket_cors_configuration" "this" {
  count  = var.cors_enabled ? 1 : 0
  bucket = aws_s3_bucket.this.id

  dynamic "cors_rule" {
    for_each = var.cors_rules
    content {
      allowed_headers = cors_rule.value.allowed_headers
      allowed_methods = cors_rule.value.allowed_methods
      allowed_origins = cors_rule.value.allowed_origins
      expose_headers  = cors_rule.value.expose_headers
      max_age_seconds = cors_rule.value.max_age_seconds
    }
  }
}

# Add Intelligent Tiering configuration
resource "aws_s3_bucket_intelligent_tiering_configuration" "this" {
  count = var.intelligent_tiering_enabled ? 1 : 0

  bucket = aws_s3_bucket.this.id
  name   = var.intelligent_tiering_config.name
  status = var.intelligent_tiering_config.status

  tiering {
    access_tier = "ARCHIVE_ACCESS"
    days        = var.intelligent_tiering_config.archive_access_tier_time
  }

  tiering {
    access_tier = "DEEP_ARCHIVE_ACCESS"
    days        = var.intelligent_tiering_config.deep_archive_access_tier_time
  }
}

# Add lifecycle rules
resource "aws_s3_bucket_lifecycle_configuration" "this" {
  count  = length(var.lifecycle_rules) > 0 ? 1 : 0
  bucket = aws_s3_bucket.this.id

  dynamic "rule" {
    for_each = var.lifecycle_rules

    content {
      id     = rule.value.id
      status = rule.value.enabled ? "Enabled" : "Disabled"

      # Add a filter block with a default prefix if not specified
      #filter {
      # prefix = ""
      #}

      dynamic "transition" {
        for_each = rule.value.transition != null ? rule.value.transition : []
        content {
          days          = transition.value.days
          storage_class = transition.value.storage_class
        }
      }

      dynamic "noncurrent_version_transition" {
        for_each = rule.value.noncurrent_version_transition != null ? rule.value.noncurrent_version_transition : []
        content {
          noncurrent_days = noncurrent_version_transition.value.days
          storage_class   = noncurrent_version_transition.value.storage_class
        }
      }

      dynamic "noncurrent_version_expiration" {
        for_each = rule.value.noncurrent_version_expiration != null ? [rule.value.noncurrent_version_expiration] : []
        content {
          noncurrent_days = noncurrent_version_expiration.value.days
        }
      }

      dynamic "expiration" {
        for_each = rule.value.expiration != null ? [rule.value.expiration] : []
        content {
          days = expiration.value.days
        }
      }
    }
  }
}

# Ensure the bucket is private
resource "aws_s3_bucket_public_access_block" "private_access" {
  count  = var.is_public ? 0 : 1
  bucket = aws_s3_bucket.this.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Add server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "encryption" {
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Create IAM policy for presigned URLs
resource "aws_iam_policy" "presigned_url_policy" {
  count       = var.is_public ? 0 : 1
  name        = "${var.bucket_name}-presigned-url-policy"
  description = "Policy for generating presigned URLs for ${var.bucket_name}"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.this.arn,
          "${aws_s3_bucket.this.arn}/*"
        ]
      }
    ]
  })
}
data "aws_lambda_function" "notification_lambda" {
  count         = var.notification_configuration != null ? 1 : 0
  function_name = var.notification_configuration.lambda_function_name
}
# Add permission for S3 to invoke Lambda
resource "aws_lambda_permission" "allow_bucket" {
  count         = var.notification_configuration != null ? 1 : 0
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = data.aws_lambda_function.notification_lambda[0].function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.this.arn
}

# Add bucket notification configuration
resource "aws_s3_bucket_notification" "bucket_notification" {
  count  = var.notification_configuration != null ? 1 : 0
  bucket = aws_s3_bucket.this.id

  lambda_function {
    lambda_function_arn = data.aws_lambda_function.notification_lambda[0].arn
    events              = var.notification_configuration.events
    filter_prefix       = var.notification_configuration.filter_prefix
  }

  depends_on = [aws_lambda_permission.allow_bucket]
}