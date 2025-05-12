vpc_cidr        = "10.10.0.0/16"
vpc_name        = "dev-vpc"
public_subnets  = ["10.10.1.0/24", "10.10.2.0/24"]
private_subnets = ["10.10.101.0/24", "10.10.102.0/24"]
azs             = ["us-east-1a", "us-east-1b"]
s3_bucket_name        = "dev-bucket-example-123456"
s3_versioning_enabled = true
s3_force_destroy      = true 