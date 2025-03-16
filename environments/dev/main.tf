# Configure the provider(s)
provider "aws" {
  region = var.region
  profile = var.profile
  default_tags {
    tags = {
      Environment = "dev"
      Project     = var.project_name
      ManagedBy   = "terraform"
    }
  }
}

# Use a data source to get the current AWS account ID
data "aws_caller_identity" "current" {}

# Development VPC
module "vpc" {
  source = "../../modules/vpc"
  
  name               = "${var.project_name}-dev"
  cidr               = var.vpc_cidr
  azs                = var.availability_zones
  private_subnets    = var.private_subnet_cidrs
  public_subnets     = var.public_subnet_cidrs
  
  enable_nat_gateway = true
  single_nat_gateway = true  # Cost-saving for dev environment
  
  tags = {
    Environment = "dev"
  }
}

# S3 bucket for development assets
resource "aws_s3_bucket" "dev_assets" {
  bucket = "${var.project_name}-dev-assets-${data.aws_caller_identity.current.account_id}"
  
  tags = {
    Name = "${var.project_name}-dev-assets"
  }
}

# Security group for development resources
resource "aws_security_group" "dev_sg" {
  name        = "${var.project_name}-dev-sg"
  description = "Security group for development resources"
  vpc_id      = module.vpc.vpc_id
  
  ingress {
    description = "SSH from dev IPs"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.dev_access_cidrs
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Example EC2 instance for development
resource "aws_instance" "dev_instance" {
  ami                    = var.instance_ami
  instance_type          = "t3.micro"  # Smaller instance for dev
  subnet_id              = module.vpc.private_subnets[0]
  vpc_security_group_ids = [aws_security_group.dev_sg.id]
  key_name               = var.ssh_key_name
  
  tags = {
    Name = "${var.project_name}-dev-instance"
  }
}

# Output important information
output "vpc_id" {
  description = "The ID of the dev VPC"
  value       = module.vpc.vpc_id
}

output "private_subnet_ids" {
  description = "The IDs of the private subnets"
  value       = module.vpc.private_subnets
}

output "public_subnet_ids" {
  description = "The IDs of the public subnets"
  value       = module.vpc.public_subnets
}

output "dev_instance_id" {
  description = "The ID of the development EC2 instance"
  value       = aws_instance.dev_instance.id
}

output "assets_bucket_name" {
  description = "The name of the S3 bucket for dev assets"
  value       = aws_s3_bucket.dev_assets.bucket
}
