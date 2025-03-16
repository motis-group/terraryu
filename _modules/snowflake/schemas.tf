// Create PUBLIC schema in RAW database
resource "snowflake_schema" "raw_public" {
  database = snowflake_database.raw.name
  name     = "PUBLIC"
  comment  = "Default schema for raw data ingestion"
}

// Create PUBLIC schema in ANALYTICS database 
resource "snowflake_schema" "analytics_public" {
  database = snowflake_database.analytics.name
  name     = "PUBLIC" 
  comment  = "Default schema for transformed analytics data"
}

// Create a staging schema in RAW for external stages
resource "snowflake_schema" "raw_staging" {
  database = snowflake_database.raw.name
  name     = "STAGING"
  comment  = "Schema for external stages and file formats"
}

// Create a reporting schema in ANALYTICS for curated views
resource "snowflake_schema" "analytics_reporting" {
  database = snowflake_database.analytics.name
  name     = "REPORTING"
  comment  = "Schema for business-facing reporting views"
}
