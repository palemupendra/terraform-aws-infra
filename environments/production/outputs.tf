# environments/prod/outputs.tf

output "data_bucket" {
  description = "Data bucket information"
  value = {
    id                  = module.data_bucket.bucket_id
    arn                 = module.data_bucket.bucket_arn
    domain_name         = module.data_bucket.bucket_domain_name
    regional_domain_name = module.data_bucket.bucket_regional_domain_name
  }
}

output "assets_bucket" {
  description = "Assets bucket information"
  value = {
    id                  = module.assets_bucket.bucket_id
    arn                 = module.assets_bucket.bucket_arn
    domain_name         = module.assets_bucket.bucket_domain_name
    website_endpoint    = module.assets_bucket.bucket_website_endpoint
  }
}

output "logs_bucket" {
  description = "Logs bucket information"
  value = {
    id          = module.logs_bucket.bucket_id
    arn         = module.logs_bucket.bucket_arn
    domain_name = module.logs_bucket.bucket_domain_name
  }
}

output "backup_bucket" {
  description = "Backup bucket information"
  value = {
    id          = module.backup_bucket.bucket_id
    arn         = module.backup_bucket.bucket_arn
    domain_name = module.backup_bucket.bucket_domain_name
  }
}

output "kms_key" {
  description = "KMS key information"
  value = {
    id    = aws_kms_key.s3_encryption.id
    arn   = aws_kms_key.s3_encryption.arn
    alias = aws_kms_alias.s3_encryption.name
  }
  sensitive = true
}