# Snowflake Terraform Module: A Chronological Guide

This README explains our Snowflake Terraform module in a step-by-step chronological order. This approach helps you understand not only what gets created, but why it's structured this way and how the components build upon each other.

## 1. Creating the Foundation: Databases

The first step is establishing our database foundation. We create two separate databases that serve different purposes in our data pipeline:

```terraform
resource "snowflake_database" "raw" {
  name    = "RAW"
  comment = "Contains raw data, landing pad for everything extracted and loaded"
}

resource "snowflake_database" "analytics" {
  name    = "ANALYTICS"
  comment = "Contains tables and views accessible to analysts and reporting"
}
```

**Why?** This separation creates a clear boundary between raw ingested data and transformed analytics-ready data. The RAW database is your landing zone for all incoming data, while the ANALYTICS database contains clean, validated data ready for business use.

## 2. Organizing Data: Schemas

Within each database, we create schemas to organize data logically:

```terraform
resource "snowflake_schema" "raw_public" {
  database = snowflake_database.raw.name
  name     = "PUBLIC"
  comment  = "Default schema for raw data"
}

resource "snowflake_schema" "analytics_public" {
  database = snowflake_database.analytics.name
  name     = "PUBLIC"
  comment  = "Default schema for analytics data"
}
```

**Why?** Schemas provide a logical organization structure within databases. While we start with PUBLIC schemas, you can add additional schemas to separate data by source, department, or data domain.

## 3. Provisioning Compute: Warehouses

Next, we create dedicated compute resources for different workloads:

```terraform
resource "snowflake_warehouse" "loading" {
  name           = var.env_name == "PROD" ? "LOADING" : "LOADING_${var.env_name}"
  warehouse_size = var.env_name == "PROD" ? "MEDIUM" : "SMALL"
  auto_suspend   = 5
  comment        = "Used by tools like Fivetran and Stitch to perform regular loads"
}

resource "snowflake_warehouse" "transforming" {
  name           = var.env_name == "PROD" ? "TRANSFORMING" : "TRANSFORMING_${var.env_name}"
  warehouse_size = var.env_name == "PROD" ? "LARGE" : "SMALL"
  auto_suspend   = 10
  comment        = "Used by dbt to perform all data transformations"
}

resource "snowflake_warehouse" "reporting" {
  name           = var.env_name == "PROD" ? "REPORTING" : "REPORTING_${var.env_name}"
  warehouse_size = var.env_name == "PROD" ? "MEDIUM" : "SMALL"
  auto_suspend   = 5
  comment        = "Used by Mode and other BI tools for analytical queries"
}
```

**Why?** Separate warehouses allow you to:
- Right-size compute for specific workloads (ETL vs. transformation vs. reporting)
- Control costs with appropriate auto-suspend settings
- Monitor and attribute resource usage to specific processes
- Prevent resource contention between workloads

## 4. Establishing Security: Roles

With our infrastructure in place, we now create roles that define what actions users can perform:

```terraform
resource "snowflake_role" "loader" {
  name    = "LOADER"
  comment = "Owns tables in the raw database and connects to the loading warehouse."
}

resource "snowflake_role" "transformer" {
  name    = "TRANSFORMER"
  comment = "Has query permissions on raw database and owns tables in analytics database."
}

resource "snowflake_role" "reporter" {
  name    = "REPORTER"
  comment = "Has permissions on the analytics database only."
}
```

**Why?** Roles implement the principle of least privilege, ensuring users only have access to what they need. Each role maps to a specific function in the data pipeline: loading, transforming, or reporting.

## 5. Creating Role Hierarchy

After creating individual roles, we establish their relationships through grants:

```terraform
resource "snowflake_role_grants" "reporter_to_transformer" {
  role_name = snowflake_role.reporter.name
  roles     = [snowflake_role.transformer.name]
}

resource "snowflake_role_grants" "transformer_to_loader" {
  role_name = snowflake_role.loader.name
  roles     = [snowflake_role.transformer.name]
}
```

This creates a hierarchy:
```
LOADER (highest privileges)
  │
  ▼
TRANSFORMER
  │
  ▼
REPORTER (lowest privileges)
```

**Why?** Role inheritance creates a clear path of privilege escalation. Higher roles (LOADER) inherit all privileges from lower roles (TRANSFORMER, REPORTER), avoiding permission duplication and simplifying management.

## 6. Assigning Database Privileges

Next, we grant specific privileges on databases and schemas:

```terraform
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
  roles         = [snowflake_role.reporter.name]
}

resource "snowflake_database_grant" "analytics_ownership_transformer" {
  database_name = snowflake_database.analytics.name
  privilege     = "OWNERSHIP"
  roles         = [snowflake_role.transformer.name]
}
```

**Why?** These grants implement our access control strategy:
- LOADER owns RAW database (can create and modify objects)
- TRANSFORMER has usage rights on RAW (can read data) and owns ANALYTICS (can create transformed data objects)
- REPORTER has usage rights on ANALYTICS (can read transformed data)

## 7. Schema and Object Privileges 

After database-level grants, we configure schema and future object grants:

```terraform
// Schema-level grants
resource "snowflake_schema_grant" "raw_usage_transformer" {
  database_name = snowflake_database.raw.name
  schema_name   = "PUBLIC"
  privilege     = "USAGE"
  roles         = [snowflake_role.transformer.name]
}

// Future grants for tables and views
resource "snowflake_table_grant" "raw_select_transformer" {
  database_name = snowflake_database.raw.name
  schema_name   = "PUBLIC"
  privilege     = "SELECT"
  roles         = [snowflake_role.transformer.name]
  on_future     = true
}

resource "snowflake_table_grant" "analytics_select_reporter" {
  database_name = snowflake_database.analytics.name
  schema_name   = "PUBLIC"
  privilege     = "SELECT"
  roles         = [snowflake_role.reporter.name]
  on_future     = true
}
```

**Why?** Future grants ensure that permissions apply automatically to new objects, maintaining consistent security as your data grows without requiring manual intervention for each new table or view.

## 8. Warehouse Access Control

We then grant warehouse usage to the appropriate roles:

```terraform
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
```

**Why?** This completes our separation of concerns by ensuring each role can only use its designated warehouse:
- LOADER uses the LOADING warehouse
- TRANSFORMER uses the TRANSFORMING warehouse
- REPORTER uses the REPORTING warehouse

## 9. Creating Users and Service Accounts

With our infrastructure and permissions configured, we create the actual user accounts:

```terraform
// Admin user
resource "snowflake_user" "admin" {
  name          = "ADMIN_USER"
  default_role  = "SYSADMIN"
}

// Service accounts for tools
resource "snowflake_user" "fivetran" {
  name              = "FIVETRAN_USER"
  default_warehouse = snowflake_warehouse.loading.name
  default_role      = snowflake_role.loader.name
}

resource "snowflake_user" "dbt" {
  name              = "DBT_USER"
  default_warehouse = snowflake_warehouse.transforming.name
  default_role      = snowflake_role.transformer.name
}

resource "snowflake_user" "tableau" {
  name              = "TABLEAU_USER"
  default_warehouse = snowflake_warehouse.reporting.name
  default_role      = snowflake_role.reporter.name
}
```

**Why?** Each service account is configured with the appropriate default role and warehouse, ensuring tools connect with the correct permissions by default.

## 10. Assigning Roles to Users

Finally, we explicitly grant roles to users:

```terraform
// Role assignments
resource "snowflake_role_grants" "fivetran_roles" {
  user_name = snowflake_user.fivetran.name
  roles     = [snowflake_role.loader.name]
}

resource "snowflake_role_grants" "dbt_roles" {
  user_name = snowflake_user.dbt.name
  roles     = [snowflake_role.transformer.name]
}

resource "snowflake_role_grants" "tableau_roles" {
  user_name = snowflake_user.tableau.name
  roles     = [snowflake_role.reporter.name]
}
```

**Why?** This completes our access control implementation by connecting users to the role-based permission structure we've built.

## The Complete Data Flow

With this architecture in place, data flows through your system like this:

1. **Data Loading**: ETL tools (Fivetran/Stitch) connect as the LOADER user, use the LOADING warehouse, and write data to the RAW database
   
2. **Data Transformation**: Transformation tools (dbt) connect as the TRANSFORMER user, use the TRANSFORMING warehouse, read from RAW, and write transformed data to ANALYTICS
   
3. **Data Consumption**: BI tools (Tableau/Mode) connect as the REPORTER user, use the REPORTING warehouse, and read from ANALYTICS

## Why This Chronological Approach Works

This step-by-step implementation:

1. **Builds a logical foundation**: Starting with databases provides the structural foundation
2. **Establishes compute resources**: Warehouses provide targeted processing power
3. **Creates security boundaries**: Roles and grants enforce separation of concerns
4. **Applies least privilege**: Each component only has the access it needs
5. **Completes with user creation**: Everything is ready before users are added

This architecture scales well as your data needs grow:
- New data sources? Add them to RAW
- New transformations? Build them in ANALYTICS
- New user types? Create new roles with appropriate permissions
- Growing workloads? Resize warehouses without changing permissions

By following this chronological deployment, you maintain a clear understanding of how each component relates to others, making the system both secure and maintainable.
