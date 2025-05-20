# Provider configuration
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Data sources to get existing VPC and subnets info
# data "aws_vpc" "selected" {
#   id = var.vpc_id
# }

# data "aws_subnets" "selected" {
#   filter {
#     name   = "vpc-id"
#     values = [var.vpc_id]
#   }
# }

# Security Group for NLB targets (if needed for application load balancing)
resource "aws_security_group" "nlb_targets" {
  name_prefix = "${var.project_name}-nlb-targets-"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-nlb-targets-sg"
    Environment = var.environment
  }
}

# Network Load Balancer
resource "aws_lb" "main" {
  name               = "${var.project_name}-nlb"
  internal           = false
  load_balancer_type = "network"
  subnets            = var.subnet_ids

  enable_deletion_protection = false

  tags = {
    Name        = "${var.project_name}-nlb"
    Environment = var.environment
  }
}

# Target Group for HTTP traffic
resource "aws_lb_target_group" "http" {
  name     = "${var.project_name}-http-tg"
  port     = 80
  protocol = "TCP"
  vpc_id   = var.vpc_id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200-399"
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 6
    unhealthy_threshold = 2
  }

  tags = {
    Name        = "${var.project_name}-http-tg"
    Environment = var.environment
  }
}

# Target Group for HTTPS traffic
resource "aws_lb_target_group" "https" {
  name     = "${var.project_name}-https-tg"
  port     = 443
  protocol = "TCP"
  vpc_id   = var.vpc_id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    port                = 80
    protocol            = "HTTP"
    path                = "/"
    timeout             = 6
    unhealthy_threshold = 2
  }

  tags = {
    Name        = "${var.project_name}-https-tg"
    Environment = var.environment
  }
}

# Listener for HTTP traffic
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.http.arn
  }
}

# Listener for HTTPS traffic
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn
  port              = "443"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.https.arn
  }
}

# Example: Attach EC2 instances to target groups (optional)
# Uncomment and modify as needed
# resource "aws_lb_target_group_attachment" "http" {
#   count            = length(var.instance_ids)
#   target_group_arn = aws_lb_target_group.http.arn
#   target_id        = var.instance_ids[count.index]
#   port             = 80
# }

# resource "aws_lb_target_group_attachment" "https" {
#   count            = length(var.instance_ids)
#   target_group_arn = aws_lb_target_group.https.arn
#   target_id        = var.instance_ids[count.index]
#   port             = 443
# }

# Outputs
output "nlb_arn" {
  description = "ARN of the Network Load Balancer"
  value       = aws_lb.main.arn
}

output "nlb_dns_name" {
  description = "DNS name of the Network Load Balancer"
  value       = aws_lb.main.dns_name
}

output "nlb_zone_id" {
  description = "Zone ID of the Network Load Balancer"
  value       = aws_lb.main.zone_id
}

output "http_target_group_arn" {
  description = "ARN of the HTTP target group"
  value       = aws_lb_target_group.http.arn
}

output "https_target_group_arn" {
  description = "ARN of the HTTPS target group"
  value       = aws_lb_target_group.https.arn
}

output "nlb_security_group_id" {
  description = "Security Group ID for NLB targets"
  value       = aws_security_group.nlb_targets.id
}