terraform {
  required_providers {
    snowflake = {
      source  = "Snowflake-Labs/snowflake"
      version = "1.0.4"
    }
  }
}

locals {
  environment_name = "staging"
}

provider "snowflake" {
  organization_name = "ZYQKSDZ"
  account_name      = "CH95471"
  user          = "WILLMARZELLA"
  role              = "ACCOUNTADMIN"
  authenticator     = "SNOWFLAKE_JWT"
  private_key       = var.SNOWFLAKE_PRIVATE_KEY
}

module "snowflake" {
  source   = "../../_modules/snowflake"
  env_name = local.environment_name
}
