// Define the custom roles
resource "snowflake_role" "loader" {
  name    = "LOADER"
  comment = "Owns tables in the raw database and connects to the loading warehouse. Used for ETL/ELT tools."
}

resource "snowflake_role" "transformer" {
  name    = "TRANSFORMER"
  comment = "Has query permissions on raw database and owns tables in analytics database. For dbt developers and scheduled jobs."
}

resource "snowflake_role" "reporter" {
  name    = "REPORTER"
  comment = "Has permissions on the analytics database only. For data consumers such as analysts and BI tools."
}

// Note on PUBLIC role:
// The PUBLIC role is a default system-defined role that can't be created via Terraform
// It is automatically assigned to all users
// We can only grant privileges to it

// Role hierarchy - inherit privileges upward
resource "snowflake_role_grants" "reporter_to_transformer" {
  role_name = snowflake_role.reporter.name
  roles     = [snowflake_role.transformer.name]
}

resource "snowflake_role_grants" "transformer_to_loader" {
  role_name = snowflake_role.loader.name
  roles     = [snowflake_role.transformer.name]
}

// User-to-role assignments are moved from users.tf to here
// Admin roles
resource "snowflake_role_grants" "admin_roles" {
  user_name = snowflake_user.admin.name
  roles     = ["SYSADMIN", "SECURITYADMIN"]
}

// Data loader users
resource "snowflake_role_grants" "stitch_roles" {
  user_name = snowflake_user.stitch.name
  roles     = [snowflake_role.loader.name]
}

resource "snowflake_role_grants" "fivetran_roles" {
  user_name = snowflake_user.fivetran.name
  roles     = [snowflake_role.loader.name]
}

// Transformation users
resource "snowflake_role_grants" "dbt_cloud_roles" {
  user_name = snowflake_user.dbt_cloud.name
  roles     = [snowflake_role.transformer.name]
}

// BI tool users
resource "snowflake_role_grants" "mode_roles" {
  user_name = snowflake_user.mode.name
  roles     = [snowflake_role.reporter.name]
}

resource "snowflake_role_grants" "looker_roles" {
  user_name = snowflake_user.looker.name
  roles     = [snowflake_role.reporter.name]
}

// Analyst users
resource "snowflake_role_grants" "dbt_analyst_roles" {
  user_name = snowflake_user.dbt_analyst.name
  roles     = [snowflake_role.transformer.name]
}

resource "snowflake_role_grants" "bi_analyst_roles" {
  user_name = snowflake_user.bi_analyst.name
  roles     = [snowflake_role.reporter.name]
}
