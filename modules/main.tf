# Production-ready S3 bucket with Terraform
# Author: Assistant
# Date: 2025-05-14

# Variables
variable "bucket_name" {
  description = "Name of the S3 bucket"
  type        = string
  default     = "my-production-bucket"
}

variable "project_name" {
  description = "Project name for resource tagging"
  type        = string
  default     = "production"
}

variable "environment" {
  description = "Environment (prod, staging, dev)"
  type        = string
  default     = "prod"
}

variable "allowed_principals" {
  description = "List of AWS principals allowed to access the bucket"
  type        = list(string)
  default     = []
}

# Random ID for unique bucket naming
resource "random_id" "bucket" {
  byte_length = 4
}

# KMS Key for S3 encryption
resource "aws_kms_key" "s3_key" {
  description             = "KMS key for S3 bucket encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = {
    Name        = "${var.project_name}-s3-key"
    Environment = var.environment
    Purpose     = "S3 Encryption"
  }
}

resource "aws_kms_alias" "s3_key_alias" {
  name          = "alias/${var.project_name}-s3-key"
  target_key_id = aws_kms_key.s3_key.key_id
}

# S3 Bucket
resource "aws_s3_bucket" "main" {
  bucket = "${var.bucket_name}-${random_id.bucket.hex}"

  tags = {
    Name        = "${var.project_name}-bucket"
    Environment = var.environment
    Purpose     = "Production Storage"
  }
}

# S3 Bucket Versioning
resource "aws_s3_bucket_versioning" "main" {
  bucket = aws_s3_bucket.main.id
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 Bucket Server-side Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  bucket = aws_s3_bucket.main.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.s3_key.arn
      sse_algorithm     = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

# S3 Bucket Public Access Block (Block all public access)
resource "aws_s3_bucket_public_access_block" "main" {
  bucket = aws_s3_bucket.main.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 Bucket Lifecycle Configuration
resource "aws_s3_bucket_lifecycle_configuration" "main" {
  bucket = aws_s3_bucket.main.id

  rule {
    id     = "transition_to_ia"
    status = "Enabled"

    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "STANDARD_IA"
    }

    noncurrent_version_transition {
      noncurrent_days = 60
      storage_class   = "GLACIER"
    }

    noncurrent_version_transition {
      noncurrent_days = 90
      storage_class   = "DEEP_ARCHIVE"
    }

    noncurrent_version_expiration {
      noncurrent_days = 365
    }
  }

  rule {
    id     = "current_version_transitions"
    status = "Enabled"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 60
      storage_class = "GLACIER"
    }

    transition {
      days          = 90
      storage_class = "DEEP_ARCHIVE"
    }
  }

  rule {
    id     = "delete_incomplete_multipart_uploads"
    status = "Enabled"

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

# S3 Bucket Logging
resource "aws_s3_bucket" "access_logs" {
  bucket = "${var.bucket_name}-access-logs-${random_id.bucket.hex}"

  tags = {
    Name        = "${var.project_name}-access-logs"
    Environment = var.environment
    Purpose     = "S3 Access Logs"
  }
}

resource "aws_s3_bucket_public_access_block" "access_logs" {
  bucket = aws_s3_bucket.access_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_logging" "main" {
  bucket = aws_s3_bucket.main.id

  target_bucket = aws_s3_bucket.access_logs.id
  target_prefix = "access-logs/"
}

# S3 Bucket Notification (optional - for monitoring)
resource "aws_s3_bucket_notification" "main" {
  bucket = aws_s3_bucket.main.id

  cloudwatch_configuration {
    cloudwatch_configuration_id = "all-objects-events"
    events                      = ["s3:ObjectCreated:*", "s3:ObjectRemoved:*"]
  }
}

# IAM Policy for S3 Bucket
resource "aws_iam_policy" "s3_policy" {
  name        = "${var.project_name}-s3-policy"
  description = "Policy for accessing the production S3 bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = [
          "${aws_s3_bucket.main.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ]
        Resource = aws_s3_bucket.main.arn
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey",
          "kms:DescribeKey"
        ]
        Resource = aws_kms_key.s3_key.arn
      }
    ]
  })
}

# Cross-Region Replication (optional)
resource "aws_iam_role" "replication" {
  name = "${var.project_name}-s3-replication-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy_attachment" "replication" {
  name       = "${var.project_name}-s3-replication-policy"
  roles      = [aws_iam_role.replication.name]
  policy_arn = "arn:aws:iam::aws:policy/service-role/S3CRRRole"
}

# S3 Replication Configuration
resource "aws_s3_bucket_replication_configuration" "main" {
  role   = aws_iam_role.replication.arn
  bucket = aws_s3_bucket.main.id

  rule {
    id     = "replicate-to-secondary-region"
    status = "Enabled"

    destination {
      bucket        = aws_s3_bucket.replica.arn
      storage_class = "STANDARD_IA"

      encryption_configuration {
        replica_kms_key_id = aws_kms_key.s3_key.arn
      }
    }
  }

  depends_on = [aws_s3_bucket_versioning.main]
}

# Replica bucket in another region (optional)
provider "aws" {
  alias  = "replica"
  region = "us-west-2"
}

resource "aws_s3_bucket" "replica" {
  provider = aws.replica
  bucket   = "${var.bucket_name}-replica-${random_id.bucket.hex}"

  tags = {
    Name        = "${var.project_name}-replica"
    Environment = var.environment
    Purpose     = "Production Storage Replica"
  }
}

resource "aws_s3_bucket_versioning" "replica" {
  provider = aws.replica
  bucket   = aws_s3_bucket.replica.id
  versioning_configuration {
    status = "Enabled"
  }
}

# CloudWatch alarms for monitoring
resource "aws_cloudwatch_metric_alarm" "bucket_size" {
  alarm_name          = "${var.project_name}-s3-bucket-size"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "BucketSizeBytes"
  namespace           = "AWS/S3"
  period              = "86400"
  statistic           = "Average"
  threshold           = "1000000000" # 1GB in bytes
  alarm_description   = "This metric monitors S3 bucket size"
  alarm_actions       = []

  dimensions = {
    BucketName  = aws_s3_bucket.main.bucket
    StorageType = "StandardStorage"
  }
}

resource "aws_cloudwatch_metric_alarm" "bucket_requests" {
  alarm_name          = "${var.project_name}-s3-high-requests"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "NumberOfObjects"
  namespace           = "AWS/S3"
  period              = "86400"
  statistic           = "Average"
  threshold           = "1000"
  alarm_description   = "This metric monitors S3 bucket object count"
  alarm_actions       = []

  dimensions = {
    BucketName  = aws_s3_bucket.main.bucket
    StorageType = "AllStorageTypes"
  }
}

# Outputs
output "bucket_name" {
  description = "Name of the S3 bucket"
  value       = aws_s3_bucket.main.bucket
}

output "bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = aws_s3_bucket.main.arn
}

output "bucket_region" {
  description = "Region of the S3 bucket"
  value       = aws_s3_bucket.main.region
}

output "kms_key_id" {
  description = "ID of the KMS key used for encryption"
  value       = aws_kms_key.s3_key.id
}

output "access_logs_bucket" {
  description = "Name of the access logs bucket"
  value       = aws_s3_bucket.access_logs.bucket
}

output "replica_bucket_name" {
  description = "Name of the replica bucket"
  value       = aws_s3_bucket.replica.bucket
}