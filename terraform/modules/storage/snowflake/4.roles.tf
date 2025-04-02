resource "snowflake_account_role" "roles" {
  name    = "${local.prefix}${each.key}"
  comment = each.value.comment
  # This "depends_on" caluase ensures all the roles are destroyed before warehouse, schema and (implicitly) database objects. 
  # This is necessary to avoid a bug where a strey-object-thread begins, but the creted ROLE with OWNERSHIP on
  # that object is destroyed in a concurrent thread, before the destroy-objectthread completes. The resuilt is a permissions error and a faled destroy command
  depends_on = [
    snowflake_warehouse.warehouses,
    snowflake_schema.schemas,
    snowflake_database.databases
  ]

  for_each = {
    "ACCOUNTADMIN" = {
      builtin = true # metadata only
      comment = "Account administrator can manage all aspects of the account, including users, roles, and warehouses."
    }
    "SYSADMIN" = {
      builtin = true # metadata only
      comment = "System administrator can create and manage databases and warehouses."
    }
    "SECURITYADMIN" = {
      builtin = true # metadata only
      comment = "Security administrator can manage security aspects of the account"
    }
    "TRANSFORMER" = {
      comment = "The dbt developer role. Owns GOLD"
    }
    "REPORTER" = {
      comment = "The analyst role. Has select privelges on specific schemas in GOLD. Used by Looker and analysts."
    }
    "LOADER" = {
      comment = "The streaming role. Used by Fivetran and event streams to write to RAW."
    }
    "USERADMIN" = {
      comment = "The user administrator role. Used to manage users."
    }
  }
}
