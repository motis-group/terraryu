// 1. Primary Account Login (Admin)
resource "snowflake_user" "users" {
  name              = "${local.prefix}${each.value.is_service_account ? "SERVICE_ACCOUNT_${each.key}" : "${each.key}"}"
  default_role      = lookup(each.value, "default_role", null)
  default_warehouse = lookup(each.value, "default_warehouse", null)
  disabled          = lookup(each.value, "disabled", null)
  login_name        = lookup(each.value, "login_name", null)
  rsa_public_key    = lookup(each.value, "rsa_public_key", null)

  for_each = {
    "WILLMARZELLA" = {
      is_service_account = false
      default_role       = snowflake_account_role.roles["ACCOUNTADMIN"].name
      default_warehouse  = snowflake_warehouse.warehouses["TRANSFORMING_WH"].name
      disabled           = false
      login_name         = "williampmarzella@gmail.com"
    }
    "TERRAFORM_SERVICE_ACCOUNT" = {
      is_service_account = true
      default_role       = snowflake_account_role.roles["SYSADMIN"].name
      default_warehouse  = snowflake_warehouse.warehouses["TRANSFORMING_WH"].name
      disabled           = false
      login_name         = "terraform_service_account"
    }
  }
}
