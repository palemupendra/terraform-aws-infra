vpc_cidr        = "10.20.0.0/16"
vpc_name        = "nonprod-vpc"
public_subnets  = ["10.20.1.0/24", "10.20.2.0/24"]
private_subnets = ["10.20.101.0/24", "10.20.102.0/24"]
azs             = ["us-east-1a", "us-east-1b"]
s3_bucket_name        = "nonprod-bucket-example-123456"
s3_versioning_enabled = true
s3_force_destroy      = true 