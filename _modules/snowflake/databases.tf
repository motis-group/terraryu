resource "snowflake_database" "raw" {
  name                        = "RAW"
  comment                     = "Contains raw data, landing pad for everything extracted and loaded, as well as external stages for data living in S3. Access to this database is strictly permissioned."
  data_retention_time_in_days = 1  # Adjust as needed
}

resource "snowflake_database" "analytics" {
  name                        = "ANALYTICS"
  comment                     = "Contains tables and views accessible to analysts and reporting. Everything in analytics is created and owned by dbt."
  data_retention_time_in_days = 1  # Adjust as needed
}
