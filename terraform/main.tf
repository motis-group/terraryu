terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
    snowflake = {
      source  = "Snowflake-Labs/snowflake"
      version = "~> 0.60"
    }
  }

  backend "s3" {
    # This will be configured via -backend-config options during terraform init
    # to support different environments
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = var.environment
      Project     = "data-platform"
      ManagedBy   = "terraform"
    }
  }
}

provider "snowflake" {
  # Credentials will be provided via environment variables:
  # SNOWFLAKE_ACCOUNT, SNOWFLAKE_USER, SNOWFLAKE_PASSWORD
  role = var.snowflake_role
}

# Variables
variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string
}

variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-west-2"
}

variable "snowflake_role" {
  description = "Snowflake role to use for operations"
  type        = string
  default     = "ACCOUNTADMIN"
}

# Module references
module "storage" {
  source      = "./modules/storage"
  environment = var.environment
}

module "compute" {
  source      = "./modules/compute"
  environment = var.environment
}

module "networking" {
  source      = "./modules/networking"
  environment = var.environment
}

module "monitoring" {
  source      = "./modules/monitoring"
  environment = var.environment
}

module "security" {
  source      = "./modules/security"
  environment = var.environment
}

# Outputs
output "data_bucket_name" {
  description = "Name of the S3 bucket for data storage"
  value       = module.storage.data_bucket_name
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster for Prefect agents"
  value       = module.compute.ecs_cluster_name
}
