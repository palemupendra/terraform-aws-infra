variable "bucket_name" {
  description = "Name of the S3 bucket"
  type        = string
  default = "madagaskarmnb123"
}

variable "versioning_enabled" {
  description = "Enable versioning for the bucket"
  type        = bool
  default     = true
}

variable "force_destroy" {
  description = "Force destroy the bucket when deleting"
  type        = bool
  default     = true
} 