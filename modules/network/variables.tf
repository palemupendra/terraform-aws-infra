variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "vpc_name" {
  description = "Name for the VPC and related resources"
  type        = string
  default = "my_vpc"
}

variable "public_subnets" {
  description = "List of public subnet CIDR blocks"
  type        = list(string)
  default = [ "10.0.1.0/24"]
}

variable "private_subnets" {
  description = "List of private subnet CIDR blocks"
  type        = list(string)
  default = [ "10.0.3.0/24" ]
}

variable "azs" {
  description = "List of availability zones to use"
  type        = list(string)
  default = [ "ap-south-1a" ]
} 