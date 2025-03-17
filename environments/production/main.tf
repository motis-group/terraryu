terraform {
  required_providers {
    snowflake = {
      source  = "Snowflake-Labs/snowflake"
      version = "1.0.4"
    }
  }
}

locals {
  environment_name = "prod"
}

provider "snowflake" {
  organization_name = "ZYQKSDZ"
  account_name      = "CH95471"
  username          = "WILLMARZELLA"
  role              = "ACCOUNTADMIN"
  authenticator     = "SNOWFLAKE_JWT"
  private_key       = var.snowflake_private_key
}

module "snowflake" {
  source   = "../../_modules/snowflake"
  env_name = local.environment_name
}

# Add dbt Cloud module that uses Snowflake infrastructure
# module "dbt" {
#   source = "../../_modules/dbt"

#   # Use project name from variables with environment suffix
#   project_prefix = "${var.project_name}-${local.environment_name}"

#   # Connect to Snowflake using outputs from Snowflake module
#   snowflake_account = var.snowflake_account
#   snowflake_analytics_database = module.snowflake.analytics_database_name
#   snowflake_transforming_warehouse = module.snowflake.transforming_warehouse_name
#   snowflake_transformer_role = module.snowflake.transformer_role_name

#   # dbt Cloud specific configuration
#   dbt_cloud_api_key = var.dbt_cloud_api_key
#   dbt_repository_url = var.dbt_repository_url
#   github_installation_id = var.github_installation_id

#   # Use credentials from Snowflake module
#   snowflake_dbt_user = module.snowflake.dbt_user_name
#   snowflake_dbt_password = var.dbt_user_password

#   # Ensure dbt resources are created after Snowflake resources
#   depends_on = [module.snowflake]
# }

# Output important values
# output "analytics_database" {
#   value = module.snowflake.analytics_database_name
#   description = "The name of the analytics database"
# }

# output "raw_database" {
#   value = module.snowflake.raw_database_name
#   description = "The name of the raw database"
# }

# output "dbt_project_id" {
#   value = module.dbt.dbt_project_id
#   description = "dbt Cloud project ID"
# }

# output "dbt_daily_job_id" {
#   value = module.dbt.dbt_prod_job_id
#   description = "dbt daily transformation job ID"
# }
