# Base project path
$basePath = "terraform-modules"
$s3ModulePath = "$basePath\modules\s3_bucket"
$envPaths = @("dev", "staging", "production") | ForEach-Object { "$basePath\environments\$_" }

# Create directories
New-Item -Path $s3ModulePath -ItemType Directory -Force | Out-Null
$envPaths | ForEach-Object { New-Item -Path $_ -ItemType Directory -Force | Out-Null }

# main.tf in S3 module
@'
resource "aws_s3_bucket" "this" {
  bucket = var.bucket_name
  acl    = var.acl

  lifecycle {
    prevent_destroy = var.prevent_destroy
  }

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}
'@ | Set-Content "$s3ModulePath\main.tf"

# variables.tf in S3 module
@'
variable "bucket_name" {
  description = "The name of the S3 bucket."
  type        = string
}

variable "acl" {
  description = "The canned ACL to apply."
  type        = string
  default     = "private"
}

variable "prevent_destroy" {
  description = "Whether to prevent destroying the bucket."
  type        = bool
  default     = false
}
'@ | Set-Content "$s3ModulePath\variables.tf"

# outputs.tf in S3 module
@'
output "bucket_name" {
  value = aws_s3_bucket.this.bucket
}
'@ | Set-Content "$s3ModulePath\outputs.tf"

# Environment-specific main.tf
$envConfig = @"
module "s3_bucket" {
  source          = "../../modules/s3_bucket"
  bucket_name     = "my-<env>-bucket-12345"
  acl             = "private"
  prevent_destroy = true
}
"@

$envPaths | ForEach-Object {
  $envName = Split-Path $_ -Leaf
  $content = $envConfig -replace "<env>", $envName
  Set-Content "$_\main.tf" $content
}

Write-Host "✅ Terraform structure created under $(Resolve-Path $basePath)"
