# modules/s3-bucket/variables.tf

variable "bucket_name" {
  description = "The name of the S3 bucket"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "force_destroy" {
  description = "Allow deletion of non-empty bucket"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Additional tags to apply to the bucket"
  type        = map(string)
  default     = {}
}

# Public access block settings
variable "block_public_acls" {
  description = "Whether Amazon S3 should block public ACLs for this bucket"
  type        = bool
  default     = true
}

variable "block_public_policy" {
  description = "Whether Amazon S3 should block public bucket policies for this bucket"
  type        = bool
  default     = true
}

variable "ignore_public_acls" {
  description = "Whether Amazon S3 should ignore public ACLs for this bucket"
  type        = bool
  default     = true
}

variable "restrict_public_buckets" {
  description = "Whether Amazon S3 should restrict public bucket policies for this bucket"
  type        = bool
  default     = true
}

# Encryption settings
variable "sse_algorithm" {
  description = "The server-side encryption algorithm to use"
  type        = string
  default     = "AES256"
  validation {
    condition     = contains(["AES256", "aws:kms"], var.sse_algorithm)
    error_message = "SSE algorithm must be either AES256 or aws:kms."
  }
}

variable "kms_master_key_id" {
  description = "The AWS KMS master key ID used for the SSE-KMS encryption"
  type        = string
  default     = null
}

variable "bucket_key_enabled" {
  description = "Whether or not to use Amazon S3 Bucket Keys for SSE-KMS"
  type        = bool
  default     = false
}

# Versioning
variable "versioning_enabled" {
  description = "Enable versioning for the S3 bucket"
  type        = bool
  default     = true
}

# Lifecycle configuration
variable "lifecycle_configuration" {
  description = "Lifecycle configuration for the S3 bucket"
  type = object({
    rules = list(object({
      id     = string
      status = string
      filter = optional(object({
        prefix = string
      }))
      expiration = optional(object({
        days = number
      }))
      noncurrent_version_expiration = optional(object({
        noncurrent_days = number
      }))
      transitions = optional(list(object({
        days          = number
        storage_class = string
      })))
    }))
  })
  default = null
}

# CORS configuration
variable "cors_configuration" {
  description = "CORS configuration for the S3 bucket"
  type = object({
    cors_rules = list(object({
      id              = optional(string)
      allowed_headers = optional(list(string))
      allowed_methods = list(string)
      allowed_origins = list(string)
      expose_headers  = optional(list(string))
      max_age_seconds = optional(number)
    }))
  })
  default = null
}

# Bucket policy
variable "bucket_policy" {
  description = "IAM policy document for the S3 bucket"
  type        = string
  default     = null
}

# Logging configuration
variable "logging_configuration" {
  description = "Logging configuration for the S3 bucket"
  type = object({
    target_bucket = string
    target_prefix = string
  })
  default = null
}