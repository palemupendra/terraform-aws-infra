module "s3_bucket" {
  source          = "../../modules/s3_bucket"
  bucket_name     = "my-dev-bucket-12345"
  acl             = "private"
  prevent_destroy = true
}
