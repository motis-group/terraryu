resource "snowflake_warehouse" "loading" {
  name           = var.env_name == "PROD" ? "LOADING" : "LOADING_${var.env_name}"
  warehouse_size = var.env_name == "PROD" ? "MEDIUM" : "SMALL"
  auto_resume    = true
  auto_suspend   = 5
  comment        = "Used by tools like Fivetran and Stitch to perform regular loads of new data. Separated from other workloads to prevent slowness for BI users."
}

resource "snowflake_warehouse" "transforming" {
  name           = var.env_name == "PROD" ? "TRANSFORMING" : "TRANSFORMING_${var.env_name}"
  warehouse_size = var.env_name == "PROD" ? "LARGE" : "SMALL"
  auto_resume    = true
  auto_suspend   = 10
  comment        = "Used by dbt to perform all data transformations. Only active during regular job runs."
}

resource "snowflake_warehouse" "reporting" {
  name           = var.env_name == "PROD" ? "REPORTING" : "REPORTING_${var.env_name}"
  warehouse_size = var.env_name == "PROD" ? "MEDIUM" : "SMALL"
  auto_resume    = true
  auto_suspend   = 5
  comment        = "Used by Mode and other BI tools for analytical queries. Only active when users are running queries."
}