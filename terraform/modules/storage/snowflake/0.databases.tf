

resource "snowflake_database" "databases" {
  name                        = "${local.prefix}${each.key}"
  comment                     = lookup(each.value, "comment", null)
  data_retention_time_in_days = lookup(each.value, "data_retention_time_in_days", null)

  for_each = {
    "GOLD" = {
      dbt_managed                 = true # metadata only
      comment                     = "Contains tables and views accessible to analysts and reporting. Everything in analytics is created and owned by dbt."
      data_retention_time_in_days = 1
    }
    "RAW" = {
      dbt_managed                 = false # raw data is not created by dbt
      comment                     = "Contains raw data, landing pad for everything extracted and loaded, as well as external stages for data living in S3. Access to this database is strictly permissioned."
      data_retention_time_in_days = 2
    }
  }
}
