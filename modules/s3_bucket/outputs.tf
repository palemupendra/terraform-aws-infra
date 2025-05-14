# modules/s3-bucket/outputs.tf

output "bucket_id" {
  description = "The ID of the S3 bucket"
  value       = aws_s3_bucket.main.id
}

output "bucket_arn" {
  description = "The ARN of the S3 bucket"
  value       = aws_s3_bucket.main.arn
}

output "bucket_domain_name" {
  description = "The bucket domain name"
  value       = aws_s3_bucket.main.bucket_domain_name
}

output "bucket_regional_domain_name" {
  description = "The bucket regional domain name"
  value       = aws_s3_bucket.main.bucket_regional_domain_name
}

output "bucket_website_endpoint" {
  description = "The website endpoint if the bucket is configured with website hosting"
  value       = aws_s3_bucket.main.website_endpoint
}

output "bucket_hosted_zone_id" {
  description = "The hosted zone ID for the bucket"
  value       = aws_s3_bucket.main.hosted_zone_id
}

output "bucket_region" {
  description = "The AWS region this bucket resides in"
  value       = aws_s3_bucket.main.region
}

output "bucket_tags" {
  description = "The tags of the S3 bucket"
  value       = aws_s3_bucket.main.tags
}