terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }

  # Initially, the backend will be local, since we're bootstrapping the resources needed for remote state
  backend "local" {
    path = "terraform.tfstate"
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

module "bootstrap" {
  source      = "../modules/bootstrap"
  environment = var.environment
  aws_region  = var.aws_region
}

# Once the bootstrap resources are created, we can manually populate the secret with initial credentials
# This is done outside of Terraform to avoid storing sensitive data in state or version control
resource "aws_secretsmanager_secret_version" "initial_placeholder" {
  secret_id = module.bootstrap.platform_credentials_secret_arn

  # This is just a placeholder - real secrets will be populated manually or via a secure CI/CD process
  secret_string = jsonencode({
    initialized = "true",
    created_at  = timestamp()
  })

  lifecycle {
    ignore_changes = [
      secret_string
    ]
  }
}

# Outputs
output "terraform_state_bucket" {
  description = "Name of the S3 bucket for Terraform state"
  value       = module.bootstrap.terraform_state_bucket
}

output "terraform_locks_table" {
  description = "Name of the DynamoDB table for Terraform locks"
  value       = module.bootstrap.terraform_locks_table
}

output "platform_credentials_secret_arn" {
  description = "ARN of the secrets manager secret for platform credentials"
  value       = module.bootstrap.platform_credentials_secret_arn
}

output "prefect_secrets_role_arn" {
  description = "ARN of the IAM role for Prefect to access secrets"
  value       = module.bootstrap.prefect_secrets_role_arn
}

# After applying this configuration, you should:
# 1. Manually update the secret in AWS Secrets Manager with real credentials
# 2. Update the backend configuration to use the created S3 bucket and DynamoDB table 
