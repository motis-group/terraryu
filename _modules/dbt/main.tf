# # provider for dbt cloud
# provider "dbt" {
#   api_key = var.dbt_cloud_api_key
# }

# # Create a dbt Cloud project
# resource "dbt_project" "analytics_project" {
#   name = "${var.project_prefix}-analytics"
# }

# # Create connection to Snowflake
# resource "dbt_connection" "snowflake_connection" {
#   project_id = dbt_project.analytics_project.id
#   name       = "Snowflake Connection"
#   type       = "snowflake"
  
#   details = jsonencode({
#     account           = var.snowflake_account
#     database          = var.snowflake_analytics_database
#     warehouse         = var.snowflake_transforming_warehouse
#     role              = var.snowflake_transformer_role
#     allow_sso         = false
#     client_session_keep_alive = true
#   })
# }

# # Create repository connection
# resource "dbt_repository" "analytics_repo" {
#   project_id = dbt_project.analytics_project.id
#   remote_url = var.dbt_repository_url
  
#   git_provider = "github" # or "gitlab", "azure_devops" as needed
  
#   # For GitHub
#   github_installation_id = var.github_installation_id
# }

# # Development environment
# resource "dbt_environment" "development" {
#   project_id   = dbt_project.analytics_project.id
#   name         = "Development"
#   dbt_version  = var.dbt_version
#   type         = "development"
  
#   deployment_mode = "ide"
  
#   credentials {
#     id = dbt_connection.snowflake_connection.id
    
#     # Use service account 
#     schema   = "dbt_dev"
    
#     # Auth details - use variables for credentials management
#     auth_type   = "password"
#     user        = var.snowflake_dbt_user
#     password    = var.snowflake_dbt_password
#   }
# }

# # Production environment
# resource "dbt_environment" "production" {
#   project_id   = dbt_project.analytics_project.id
#   name         = "Production"
#   dbt_version  = var.dbt_version
#   type         = "deployment"
  
#   deployment_mode = "production"
  
#   credentials {
#     id = dbt_connection.snowflake_connection.id
    
#     # Use service account with production schema
#     schema   = "dbt_prod"
    
#     # Auth details - use variables for credentials management
#     auth_type   = "password"
#     user        = var.snowflake_dbt_user
#     password    = var.snowflake_dbt_password
#   }
# }

# # Daily transformation job
# resource "dbt_job" "daily_transformation" {
#   environment_id = dbt_environment.production.id
  
#   name         = "Daily Full Refresh"
#   execute_steps = ["dbt build --full-refresh"]
  
#   # Run daily at 1 AM UTC
#   schedule {
#     cron = "0 1 * * *"
#     date = {
#       type = "every_day"
#     }
#   }
  
#   # Trigger settings
#   triggers {
#     github_webhook = true
#     git_provider_webhook = true
#     schedule = true
#   }
  
#   # Set timeout and notifications
#   settings {
#     threads = 4
#     target_name = "prod"
#     timeout_seconds = 3600  # 1 hour
#   }
# }

# # Continuous Integration job
# resource "dbt_job" "ci_job" {
#   environment_id = dbt_environment.development.id
  
#   name         = "CI Tests"
#   execute_steps = ["dbt build --full-refresh --select state:modified"]
  
#   # Don't schedule, only run on PR
#   schedule {
#     cron = "0 0 31 2 *"  # Never run (Feb 31)
#     date = {
#       type = "custom"
#     }
#   }
  
#   # Trigger on PRs
#   triggers {
#     github_webhook = true
#     git_provider_webhook = true
#     schedule = false
#   }
  
#   # Set timeout and notifications
#   settings {
#     threads = 4
#     target_name = "dev"
#     timeout_seconds = 1800  # 30 minutes
#   }
# }

# # Service account for dbt Cloud
# resource "dbt_service_token" "cicd_token" {
#   name = "cicd-token"
#   service_token_permissions {
#     project_id = dbt_project.analytics_project.id
#     permission_set = "member"
#   }
# }

# # Outputs
# output "dbt_project_id" {
#   value = dbt_project.analytics_project.id
#   description = "dbt Cloud Project ID"
# }

# output "dbt_prod_job_id" {
#   value = dbt_job.daily_transformation.id
#   description = "Daily transformation job ID"
# }

# output "dbt_cicd_token" {
#   value = dbt_service_token.cicd_token.token_string
#   description = "CICD token for dbt Cloud API access"
#   sensitive = true
# }


