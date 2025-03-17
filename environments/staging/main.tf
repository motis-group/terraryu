terraform {
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
      version = "~> 0.87"
    }
  }
}

locals {
  environment_name = "staging"
}

provider "snowflake" {
  user              = "WILLMARZELLA"
  organization_name = "ZYQKSDZ"
  account_name      = "CH95471"
  role              = "ACCOUNTADMIN"
  authenticator     = "SNOWFLAKE_JWT"
  private_key       = var.snowflake_private_key
}

module "snowflake" {
  source   = "../../_modules/snowflake"
  env_name = local.environment_name
}