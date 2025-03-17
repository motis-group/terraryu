terraform {
  required_providers {
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
  private_key       = var.SNOWFLAKE_PRIVATE_KEY
}

module "snowflake" {
  source   = "../../_modules/snowflake"
  env_name = local.environment_name
}