// 1. Primary Account Login (Admin)
resource "snowflake_user" "admin" {
  name                 = "ADMIN_USER"
  default_warehouse    = "TRANSFORMING" // Using more powerful warehouse as default
  default_role         = "SYSADMIN"
  must_change_password = true
  
  // Note: In production, use a more secure method like encrypted variables
  // or secret management for passwords
  password             = var.admin_password
  
  comment              = "Primary admin account - use only for administration tasks"
}

// 2. Data Loader Users (ETL/ELT tools)
resource "snowflake_user" "stitch" {
  name              = "STITCH_USER"
  default_warehouse = snowflake_warehouse.loading.name
  default_role      = snowflake_role.loader.name
  comment           = "Service account for Stitch data integration"
  password          = var.stitch_password
}

resource "snowflake_user" "fivetran" {
  name              = "FIVETRAN_USER"
  default_warehouse = snowflake_warehouse.loading.name
  default_role      = snowflake_role.loader.name
  comment           = "Service account for Fivetran data integration"
  password          = var.fivetran_password
}

// 3. Transformation Scheduler Users
resource "snowflake_user" "dbt_cloud" {
  name              = "DBT_CLOUD"
  default_warehouse = snowflake_warehouse.transforming.name
  default_role      = snowflake_role.transformer.name
  comment           = "Service account for dbt Cloud scheduled jobs"
  password          = var.dbt_cloud_password
}

// 4. BI Tool Users
resource "snowflake_user" "mode" {
  name              = "MODE_USER"
  default_warehouse = snowflake_warehouse.reporting.name
  default_role      = snowflake_role.reporter.name
  comment           = "Service account for Mode Analytics"
  password          = var.mode_password
}

resource "snowflake_user" "looker" {
  name              = "LOOKER_USER"
  default_warehouse = snowflake_warehouse.reporting.name
  default_role      = snowflake_role.reporter.name
  comment           = "Service account for Looker"
  password          = var.looker_password
}

// 5. Analyst Users
// Example of an analyst who builds dbt models (needs transformer role)
resource "snowflake_user" "dbt_analyst" {
  name                 = "ANALYST_JANE"
  default_warehouse    = snowflake_warehouse.transforming.name
  default_role         = snowflake_role.transformer.name
  must_change_password = true
  password             = var.analyst_jane_password
  email                = "jane@example.com"
  comment              = "Data analyst working with dbt models"
}

// Example of an analyst who only consumes data (needs reporter role)
resource "snowflake_user" "bi_analyst" {
  name                 = "ANALYST_JOHN"
  default_warehouse    = snowflake_warehouse.reporting.name
  default_role         = snowflake_role.reporter.name
  must_change_password = true
  password             = var.analyst_john_password
  email                = "john@example.com"
  comment              = "Business analyst who consumes data via reporting"
}

// Variables for passwords (define these in variables.tf and set values in terraform.tfvars)
variable "admin_password" {
  description = "Password for admin user"
  type        = string
  sensitive   = true
}

variable "stitch_password" {
  description = "Password for Stitch integration user"
  type        = string
  sensitive   = true
}

variable "fivetran_password" {
  description = "Password for Fivetran integration user"
  type        = string
  sensitive   = true
}

variable "dbt_cloud_password" {
  description = "Password for dbt Cloud user"
  type        = string
  sensitive   = true
}

variable "mode_password" {
  description = "Password for Mode Analytics user"
  type        = string
  sensitive   = true
}

variable "looker_password" {
  description = "Password for Looker user"
  type        = string
  sensitive   = true
}

variable "analyst_jane_password" {
  description = "Password for Analyst Jane"
  type        = string
  sensitive   = true
}

variable "analyst_john_password" {
  description = "Password for Analyst John"
  type        = string
  sensitive   = true
}
