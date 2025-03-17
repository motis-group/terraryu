################
# DATABASE GRANTS
################

# Grant privileges (except OWNERSHIP) to account roles on databases
resource "snowflake_grant_privileges_to_account_role" "database_grants" {
  for_each = {
    for pair in flatten([
      for db_name, config in {
        (snowflake_database.databases["RAW"].name) = {
          grants = [
            {
              privilege = "USAGE"
              roles     = [snowflake_account_role.roles["TRANSFORMER"].name, snowflake_account_role.roles["LOADER"].name]
            }
          ]
        },
        (snowflake_database.databases["GOLD"].name) = {
          grants = [
            {
              privilege = "USAGE"
              roles     = [snowflake_account_role.roles["REPORTER"].name, snowflake_account_role.roles["TRANSFORMER"].name]
            }
          ]
        }
        } : [
        for grant in config.grants : [
          for role_name in grant.roles : {
            database_name = db_name
            privilege     = grant.privilege
            role_name     = role_name
          }
        ]
      ]
    ]) : "${pair.role_name}-${pair.privilege}-${pair.database_name}" => pair
  }

  account_role_name = each.value.role_name
  privileges        = [each.value.privilege]
  on_account_object {
    object_type = "DATABASE"
    object_name = each.value.database_name
  }

  depends_on = [
    snowflake_account_role.roles
  ]
}

# Grant ownership to account roles on databases
resource "snowflake_grant_ownership" "database_ownership" {
  for_each = {
    for pair in flatten([
      for db_name, config in {
        (snowflake_database.databases["RAW"].name) = {
          owner_role = snowflake_account_role.roles["LOADER"].name
        },
        (snowflake_database.databases["GOLD"].name) = {
          owner_role = snowflake_account_role.roles["TRANSFORMER"].name
        }
        } : {
        database_name = db_name
        role_name     = config.owner_role
      }
    ]) : "${pair.role_name}-${pair.database_name}" => pair
  }

  account_role_name   = each.value.role_name
  outbound_privileges = "COPY"
  on {
    object_type = "DATABASE"
    object_name = each.value.database_name
  }

  depends_on = [
    snowflake_account_role.roles
  ]
}


################
# SCHEMA GRANTS
################

# Grant privileges (except OWNERSHIP) to account roles on schemas
resource "snowflake_grant_privileges_to_account_role" "schema_grants" {
  for_each = {
    for pair in flatten([
      for db_name, schemas in {
        (snowflake_database.databases["RAW"].name) = {
          "PUBLIC" = {
            grants = [
              {
                privilege = "USAGE"
                roles     = [snowflake_account_role.roles["TRANSFORMER"].name, snowflake_account_role.roles["LOADER"].name]
              }
            ]
          },
          "FIVETRAN" = {
            grants = [
              {
                privilege = "USAGE"
                roles     = [snowflake_account_role.roles["TRANSFORMER"].name, snowflake_account_role.roles["LOADER"].name]
              }
            ]
          }
        },
        (snowflake_database.databases["GOLD"].name) = {
          "PUBLIC" = {
            grants = [
              {
                privilege = "USAGE"
                roles     = [snowflake_account_role.roles["REPORTER"].name, snowflake_account_role.roles["TRANSFORMER"].name]
              }
            ]
          }
        }
        } : [
        for schema_name, v in schemas : [
          for grant in v.grants : [
            for role_name in grant.roles : {
              database_name = db_name
              schema_name   = schema_name
              privilege     = grant.privilege
              role_name     = role_name
            }
          ] if grant.privilege == "USAGE"
        ]
      ]
    ]) : "${pair.role_name}-${pair.privilege}-${pair.database_name}-${pair.schema_name}" => pair
  }

  account_role_name = each.value.role_name
  privileges        = [each.value.privilege]
  on_schema {
    schema_name = "\"${each.value.database_name}\".\"${each.value.schema_name}\""
  }

  depends_on = [
    snowflake_account_role.roles,
    snowflake_grant_privileges_to_account_role.database_grants
  ]
}

# Grant ownership to account roles on schemas
resource "snowflake_grant_ownership" "schema_ownership" {
  for_each = {
    for pair in flatten([
      for db_name, schemas in {
        (snowflake_database.databases["RAW"].name) = {
          "PUBLIC" = {
            owner_role = snowflake_account_role.roles["LOADER"].name
          },
          "FIVETRAN" = {
            owner_role = snowflake_account_role.roles["LOADER"].name
          }
        },
        (snowflake_database.databases["GOLD"].name) = {
          "PUBLIC" = {
            owner_role = snowflake_account_role.roles["TRANSFORMER"].name
          }
        }
        } : [
        for schema_name, v in schemas : {
          database_name = db_name
          schema_name   = schema_name
          role_name     = v.owner_role
        }
      ]
    ]) : "${pair.role_name}-${pair.database_name}-${pair.schema_name}" => pair
  }

  account_role_name   = each.value.role_name
  outbound_privileges = "COPY"
  on {
    object_type = "SCHEMA"
    object_name = "\"${each.value.database_name}\".\"${each.value.schema_name}\""
  }

  depends_on = [
    snowflake_account_role.roles,
    snowflake_grant_privileges_to_account_role.schema_grants
  ]
}


################
# ROLES
################

# Grant roles to users
resource "snowflake_grant_account_role" "role_grants_to_users" {
  for_each = {
    for pair in flatten([
      for role_name, config in {
        (snowflake_account_role.roles["ACCOUNTADMIN"].name) = {
          users = [
            snowflake_user.users["WILLMARZELLA"].name,
            snowflake_user.users["TERRAFORM_SERVICE_ACCOUNT"].name
          ]
        },
        (snowflake_account_role.roles["SYSADMIN"].name) = {
          users = [
            snowflake_user.users["WILLMARZELLA"].name,
            snowflake_user.users["TERRAFORM_SERVICE_ACCOUNT"].name
          ]
        },
        (snowflake_account_role.roles["REPORTER"].name) = {
          users = ["LOOKER_SERVICE_ACCOUNT", "REDASH_SERVICE_ACCOUNT"]
        },
        (snowflake_account_role.roles["TRANSFORMER"].name) = {
          users = ["DBT_SERVICE_ACCOUNT", "DATA_PLATFORM_SERVICE_ACCOUNT"]
        },
        (snowflake_account_role.roles["LOADER"].name) = {
          users = ["FIVETRAN_SERVICE_ACCOUNT", "EVENT_PIPELINE_SERVICE_ACCOUNT"]
        }
        } : [
        for user_name in config.users : {
          role = role_name
          user = user_name
        }
      ]
    ]) : "${pair.role}-${pair.user}" => pair
  }

  role_name = each.value.role
  user_name = each.value.user
}

# Grant roles to parent roles
resource "snowflake_grant_account_role" "role_grants_to_roles" {
  for_each = {
    for pair in flatten([
      for role_name, config in {
        (snowflake_account_role.roles["SYSADMIN"].name) = {
          parent_roles = [snowflake_account_role.roles["ACCOUNTADMIN"].name]
        },
        (snowflake_account_role.roles["REPORTER"].name) = {
          parent_roles = [snowflake_account_role.roles["TRANSFORMER"].name]
        },
        (snowflake_account_role.roles["TRANSFORMER"].name) = {
          parent_roles = [snowflake_account_role.roles["SYSADMIN"].name]
        },
        (snowflake_account_role.roles["LOADER"].name) = {
          parent_roles = [snowflake_account_role.roles["SYSADMIN"].name]
        }
        } : [
        for parent_role in config.parent_roles : {
          role        = role_name
          parent_role = parent_role
        }
      ]
    ]) : "${pair.role}-${pair.parent_role}" => pair
  }

  role_name        = each.value.role
  parent_role_name = each.value.parent_role
}
