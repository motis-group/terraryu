resource "snowflake_warehouse" "warehouses" {
  name                                = "${local.prefix}${each.key}"
  comment                             = each.value.comment
  warehouse_size                      = each.value.warehouse_size
  auto_resume                         = each.value.auto_resume
  auto_suspend                        = each.value.auto_suspend
  enable_query_acceleration           = false
  query_acceleration_max_scale_factor = 0

  for_each = {
    "LOADING" = {
      warehouse_size = var.env_name == "prod" ? "MEDIUM" : (var.env_name == "staging" ? "SMALL" : "XSMALL")
      auto_resume    = true
      auto_suspend   = 5
      comment        = "Used by tools like Fivetran and Stitch to perform regular loads of new data. Separated from other workloads to prevent slowness for BI users."
    }
    "TRANSFORMING_WH" = {
      warehouse_size = var.env_name == "prod" ? "LARGE" : (var.env_name == "staging" ? "MEDIUM" : "XSMALL")
      auto_resume    = true
      auto_suspend   = 10
      comment        = "Used by dbt to perform all data transformations. Only active during regular job runs."
    }
    "REPORTING" = {
      warehouse_size = var.env_name == "prod" ? "MEDIUM" : (var.env_name == "staging" ? "SMALL" : "XSMALL")
      auto_resume    = true
      auto_suspend   = 5
      comment        = "Used by Mode and other BI tools for analytical queries. Only active when users are running queries."
    }
  }
}


