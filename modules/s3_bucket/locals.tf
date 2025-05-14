# environments/common/locals.tf

locals {
  # Common configuration across all environments
  project_name = "myapp"
  
  # Common tags applied to all resources
  common_tags = {
    Project   = local.project_name
    Owner     = "DevOps Team"
    ManagedBy = "Terraform"
  }
  
  # Common lifecycle configuration
  standard_lifecycle_config = {
    rules = [
      {
        id     = "standard_lifecycle"
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
          noncurrent_days = 90
        }
      }
    ]
  }
  
  # Common CORS configuration for web applications
  standard_cors_config = {
    cors_rules = [
      {
        allowed_methods = ["GET", "HEAD", "PUT", "POST", "DELETE"]
        allowed_origins = ["*"]
        allowed_headers = ["*"]
        max_age_seconds = 3000
      }
    ]
  }
}