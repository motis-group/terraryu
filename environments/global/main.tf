terraform {
  # Assumes s3 bucket and dynamo DB table already set up
  # See /_modules/backend
  backend "s3" {
    bucket         = "motis-group-tf-state"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-locking"
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
    snowflake = {
      source  = "Snowflake-Labs/snowflake"
      version = "~> 0.45"
    }
  }
}

# AWS provider for global AWS resources
provider "aws" {
  region = "us-east-1"
}

# Other global resources could be added here:
# - Shared S3 buckets
# - IAM roles for cross-account access
# - KMS keys for encryption
# - Global security groups


