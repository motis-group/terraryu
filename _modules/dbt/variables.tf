variable "project_prefix" {
  description = "Prefix to add to project names"
  type        = string
  default     = "data"
}

variable "dbt_cloud_api_key" {
  description = "API key for dbt Cloud"
  type        = string
  sensitive   = true
}

variable "snowflake_account" {
  description = "Snowflake account identifier"
  type        = string
}

variable "snowflake_analytics_database" {
  description = "Name of the analytics database in Snowflake"
  type        = string
  default     = "ANALYTICS"
}

variable "snowflake_transforming_warehouse" {
  description = "Name of the transforming warehouse in Snowflake"
  type        = string
  default     = "TRANSFORMING"
}

variable "snowflake_transformer_role" {
  description = "Name of the transformer role in Snowflake"
  type        = string
  default     = "TRANSFORMER"
}

variable "snowflake_dbt_user" {
  description = "Username for dbt Cloud to connect to Snowflake"
  type        = string
  default     = "DBT_USER"
}

variable "snowflake_dbt_password" {
  description = "Password for the dbt Cloud Snowflake user"
  type        = string
  sensitive   = true
}

variable "dbt_repository_url" {
  description = "Git repository URL for dbt code"
  type        = string
}

variable "github_installation_id" {
  description = "GitHub App installation ID (required if using GitHub)"
  type        = string
  default     = ""
}

variable "dbt_version" {
  description = "Version of dbt to use"
  type        = string
  default     = "1.5.3"
} 