
// Snowflake Privilege Management Strategy
//
// 1. WHY - Security Design Philosophy:
//    - Follow principle of least privilege
//    - Grant access at highest applicable level (database -> schema -> object)
//    - Make permissions inheritance clear and maintainable
//    - Separate data access from compute access
//
// 2. HOW - Privilege Implementation Approach:
//    a) Start with database-level grants
//       - USAGE grants for read access
//       - OWNERSHIP grants for write access
//    b) Add schema-level permissions
//       - Use FUTURE grants to auto-apply to new objects
//       - Maintain consistent access patterns
//    c) Configure object-level grants only when necessary
//       - Specific table/view permissions
//       - Special case handling
//    d) Separate compute resources (warehouses)
//       - Dedicated warehouses per workload type
//       - Size appropriately for use case
//
// 3. WHAT - Role-Based Access Control:
//    LOADER role:
//    - Owns RAW database
//    - Uses LOADING warehouse
//    - For ELT tools (Fivetran, Stitch)
//
//    TRANSFORMER role:
//    - Reads from RAW
//    - Owns ANALYTICS
//    - Uses TRANSFORMING warehouse
//    - For dbt and analysts building models
//
//    REPORTER role:
//    - Reads from ANALYTICS only
//    - Uses REPORTING warehouse
//    - For BI tools and analysts


// Database access grants
resource "snowflake_database_grant" "raw_usage_transformer" {
  database_name = snowflake_database.raw.name
  privilege     = "USAGE"
  roles         = [snowflake_role.transformer.name]
}

resource "snowflake_database_grant" "raw_ownership_loader" {
  database_name = snowflake_database.raw.name
  privilege     = "OWNERSHIP"
  roles         = [snowflake_role.loader.name]
}

resource "snowflake_database_grant" "analytics_usage_reporter" {
  database_name = snowflake_database.analytics.name
  privilege     = "USAGE"
  roles         = [snowflake_role.reporter.name, snowflake_role.transformer.name]
}

resource "snowflake_database_grant" "analytics_ownership_transformer" {
  database_name = snowflake_database.analytics.name
  privilege     = "OWNERSHIP"
  roles         = [snowflake_role.transformer.name]
}

// Schema-level grants
// We will create PUBLIC schema grants with on_future=true for new objects
resource "snowflake_schema_grant" "raw_usage_transformer" {
  database_name = snowflake_database.raw.name
  schema_name   = "PUBLIC"
  privilege     = "USAGE"
  roles         = [snowflake_role.transformer.name]
}

resource "snowflake_schema_grant" "analytics_usage_reporter" {
  database_name = snowflake_database.analytics.name
  schema_name   = "PUBLIC"
  privilege     = "USAGE"
  roles         = [snowflake_role.reporter.name, snowflake_role.transformer.name]
}

// Warehouse access grants
resource "snowflake_warehouse_grant" "loading_usage" {
  warehouse_name = snowflake_warehouse.loading.name
  privilege      = "USAGE"
  roles          = [snowflake_role.loader.name]
}

resource "snowflake_warehouse_grant" "transforming_usage" {
  warehouse_name = snowflake_warehouse.transforming.name
  privilege      = "USAGE"
  roles          = [snowflake_role.transformer.name]
}

resource "snowflake_warehouse_grant" "reporting_usage" {
  warehouse_name = snowflake_warehouse.reporting.name
  privilege      = "USAGE"
  roles          = [snowflake_role.reporter.name]
}

// Future grants for tables and views
resource "snowflake_table_grant" "analytics_select_reporter" {
  database_name = snowflake_database.analytics.name
  schema_name   = "PUBLIC"
  privilege     = "SELECT"
  roles         = [snowflake_role.reporter.name]
  on_future     = true
}

resource "snowflake_table_grant" "raw_select_transformer" {
  database_name = snowflake_database.raw.name
  schema_name   = "PUBLIC"
  privilege     = "SELECT"
  roles         = [snowflake_role.transformer.name]
  on_future     = true
}

// Additional grants for transformer role to modify analytics objects
resource "snowflake_table_grant" "analytics_modify_transformer" {
  database_name = snowflake_database.analytics.name
  schema_name   = "PUBLIC"
  privilege     = "INSERT,UPDATE,DELETE,TRUNCATE,REFERENCES"
  roles         = [snowflake_role.transformer.name]
  on_future     = true
}

// Additional grants for loader role to modify raw objects
resource "snowflake_table_grant" "raw_modify_loader" {
  database_name = snowflake_database.raw.name
  schema_name   = "PUBLIC"
  privilege     = "INSERT,UPDATE,DELETE,TRUNCATE,REFERENCES"
  roles         = [snowflake_role.loader.name]
  on_future     = true
}
