locals {
  resource_prefix = "${var.project}-${var.env_name}"
}

# Provider configuration and module initialization
terraform {
  required_providers {
    snowflake = {
      source  = "Snowflake-Labs/snowflake"
      version = "~> 0.66.0"
    }
  }
}

# Note: Specific resources are now managed in their dedicated files:
# - databases.tf: Database definitions
# - warehouses.tf: Compute resources
# - roles.tf: Role definitions and user-role assignments
# - users.tf: User accounts
# - grants.tf: Privilege management