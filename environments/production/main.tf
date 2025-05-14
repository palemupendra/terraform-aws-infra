# environments/prod/main.tf

terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  
  # Backend configuration for state management
  backend "s3" {
    bucket = "terraform-state-prod-bucket"  # Replace with your state bucket
    key    = "s3-buckets/terraform.tfstate"
    region = "us-east-1"
    
    # DynamoDB table for state locking
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}

# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = merge(
      local.common_tags,
      {
        Environment = var.environment
      }
    )
  }
}

# Import common configuration
module "common" {
  source = "../common"
}

# Create KMS key for encryption in production
resource "aws_kms_key" "s3_encryption" {
  description             = "KMS key for S3 bucket encryption in production"
  deletion_window_in_days = 7
  
  tags = merge(
    local.common_tags,
    {
      Name        = "${local.common.project_name}-${var.environment}-s3-key"
      Environment = var.environment
    }
  )
}

resource "aws_kms_alias" "s3_encryption" {
  name          = "alias/${local.common.project_name}-${var.environment}-s3"
  target_key_id = aws_kms_key.s3_encryption.key_id
}

# Data bucket for production
module "data_bucket" {
  source = "../../modules/s3-bucket"
  
  bucket_name  = "${local.common.project_name}-${var.environment}-data"
  environment  = var.environment
  project_name = local.common.project_name
  
  # Production-specific settings
  force_destroy      = false  # Prevent accidental deletion
  versioning_enabled = true   # Enable versioning for data safety
  
  # Use KMS encryption for sensitive data
  sse_algorithm     = "aws:kms"
  kms_master_key_id = aws_kms_key.s3_encryption.arn
  bucket_key_enabled = true  # Cost optimization
  
  # Extended lifecycle for production
  lifecycle_configuration = {
    rules = [
      {
        id     = "production_lifecycle"
        status = "Enabled"
        
        transitions = [
          {
            days          = 30
            storage_class = "STANDARD_IA"
          },
          {
            days          = 90
            storage_class = "GLACIER"
          },
          {
            days          = 365
            storage_class = "DEEP_ARCHIVE"
          }
        ]
        
        noncurrent_version_expiration = {
          noncurrent_days = 365  # Keep old versions longer in prod
        }
      }
    ]
  }
  
  # Additional production tags
  tags = {
    Type        = "data"
    Purpose     = "Production data storage"
    CostCenter  = "Operations"
    Compliance  = "required"
    Backup      = "required"
  }
}

# Static assets bucket for production
module "assets_bucket" {
  source = "../../modules/s3-bucket"
  
  bucket_name  = "${local.common.project_name}-${var.environment}-assets"
  environment  = var.environment
  project_name = local.common.project_name
  
  # Keep public access blocked by default
  # Configure CloudFront or specific policies as needed
  
  # CORS for web assets
  cors_configuration = local.common.standard_cors_config
  
  # Production asset lifecycle
  lifecycle_configuration = {
    rules = [
      {
        id     = "asset_lifecycle"
        status = "Enabled"
        
        # Keep current versions indefinitely
        noncurrent_version_expiration = {
          noncurrent_days = 30  # Delete old versions after 30 days
        }
      }
    ]
  }
  
  tags = {
    Type     = "assets"
    Purpose  = "Static web assets"
    Public   = "false"  # Control access via CloudFront
  }
}

# Logs bucket for production
module "logs_bucket" {
  source = "../../modules/s3-bucket"
  
  bucket_name  = "${local.common.project_name}-${var.environment}-logs"
  environment  = var.environment
  project_name = local.common.project_name
  
  # Versioning not needed for logs
  versioning_enabled = false
  
  # Encryption for logs
  sse_algorithm = "AES256"
  
  # Extended retention for production logs
  lifecycle_configuration = {
    rules = [
      {
        id     = "log_lifecycle"
        status = "Enabled"
        
        transitions = [
          {
            days          = 30
            storage_class = "STANDARD_IA"
          },
          {
            days          = 90
            storage_class = "GLACIER"
          }
        ]
        
        expiration = {
          days = 2555  # Keep logs for 7 years (compliance)
        }
      }
    ]
  }
  
  tags = {
    Type       = "logs"
    Purpose    = "Application logs"
    Backup     = "true"
    Retention  = "7-years"
    Compliance = "required"
  }
}

# Backup bucket for production
module "backup_bucket" {
  source = "../../modules/s3-bucket"
  
  bucket_name  = "${local.common.project_name}-${var.environment}-backup"
  environment  = var.environment
  project_name = local.common.project_name
  
  # Maximum security for backups
  versioning_enabled = true
  
  # KMS encryption for backups
  sse_algorithm     = "aws:kms"
  kms_master_key_id = aws_kms_key.s3_encryption.arn
  bucket_key_enabled = true
  
  # Long-term retention for backups
  lifecycle_configuration = {
    rules = [
      {
        id     = "backup_lifecycle"
        status = "Enabled"
        
        transitions = [
          {
            days          = 1
            storage_class = "STANDARD_IA"
          },
          {
            days          = 30
            storage_class = "GLACIER"
          },
          {
            days          = 90
            storage_class = "DEEP_ARCHIVE"
          }
        ]
        
        # Keep backups for 10 years
        expiration = {
          days = 3650
        }
        
        noncurrent_version_expiration = {
          noncurrent_days = 30
        }
      }
    ]
  }
  
  tags = {
    Type       = "backup"
    Purpose    = "System backups"
    Backup     = "true"
    Compliance = "required"
    Retention  = "10-years"
  }
}