resource "snowflake_schema" "schemas" {

  # local.prefix is defined by the workspace

  name                = "${local.prefix}${each.key}"
  comment             = each.value.comment
  database            = each.value.database
  with_managed_access = false
  is_transient        = false

  for_each = {
    "EVENT_LOG" = {
      database = snowflake_database.databases["RAW"].name
      comment  = "Raw event log destination"
    }
  }
}
