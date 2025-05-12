resource "aws_s3_bucket" "this" {
  bucket = var.bucket_name
  force_destroy = var.force_destroy
  tags = {
    Name = var.bucket_name
  }
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id
  versioning_configuration {
    status = var.versioning_enabled ? "Enabled" : "Suspended"
  }
  } 
  resource "aws_s3_bucket_policy" "this" {
    bucket = aws_s3_bucket.this.id
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Principal = {
          "AWS"= "arn:aws:iam::061051247919:root"
          }
          Action = "s3:GetObject"
          Resource = "${aws_s3_bucket.this.arn}/*"
        }
      ]
    })
  }
