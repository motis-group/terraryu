# dbt Cloud Terraform Module

This module provisions dbt Cloud resources to integrate with our Snowflake data warehouse. It sets up the necessary project, environments, connections, and jobs to enable analytics engineers to create and manage views and transformations through dbt.

## Purpose

This module allows analysts to create and manage views and transformations in a SQL-friendly, version-controlled way, while maintaining integration with our core Snowflake infrastructure. By moving view management out of Terraform and into dbt, we:

1. **Improve analyst agility**: Data analysts can create and modify views without needing Terraform or infrastructure knowledge
2. **Maintain version control**: All changes are tracked in Git, providing history and the ability to revert
3. **Enable testing**: dbt's testing framework ensures data quality and reliability
4. **Streamline deployment**: CI/CD integration automates the deployment of validated changes
5. **Enforce documentation**: dbt encourages documentation for all models

## Architecture Integration

Within our overall data architecture, dbt Cloud serves as the transformation layer:

```
┌────────────────────────┐
│   Snowflake (IaC)      │
├────────────────────────┤
│ Databases              │
│ Schemas                │
│ Core Tables            │
│ Warehouses             │
│ Roles & Access Control │
└─────────────┬──────────┘
              │
              │ connects to
              ▼
┌────────────────────────┐
│   dbt Cloud (IaC)      │
├────────────────────────┤
│ Project                │
│ Environments           │
│ Snowflake Connection   │
│ Jobs & Schedules       │
└─────────────┬──────────┘
              │
              │ deploys
              ▼
┌────────────────────────┐
│   dbt Models (SQL)     │
├────────────────────────┤
│ Transformations        │
│ Views                  │
│ Aggregations           │
│ Data Tests             │
│ Documentation          │
└────────────────────────┘
```

## Resources Created

This module provisions:

1. **dbt Cloud Project**: A container for all dbt resources
2. **Snowflake Connection**: Securely connects to Snowflake using the TRANSFORMER role
3. **Development Environment**: For analysts to build and test models
4. **Production Environment**: For scheduled runs and deployments
5. **Repository Connection**: Links to your Git repository containing dbt code
6. **Scheduled Jobs**: Automates the refresh of your models
7. **CI Testing**: Validates changes during pull requests

## Usage

To use this module, you'll need:

1. A dbt Cloud account and API key
2. A Git repository for your dbt code
3. The existing Snowflake infrastructure from our Snowflake module

```terraform
module "dbt" {
  source = "../_modules/dbt"

  project_prefix     = "mycompany"
  snowflake_account  = "myorgid-accountname"
  dbt_repository_url = "https://github.com/myorg/dbt-analytics"

  # Security-sensitive variables should be provided via environment variables
  # or a secure vault integration
  dbt_cloud_api_key    = var.dbt_cloud_api_key
  snowflake_dbt_password = var.snowflake_dbt_password
}
```

## Workflow for Analysts

With this architecture, analysts follow this workflow:

1. Develop models locally or in dbt Cloud IDE
2. Commit changes to a feature branch
3. Create a PR to trigger CI testing
4. After approval, merge to main
5. dbt Cloud automatically deploys the changes

This enables rapid iteration on views and transformations without requiring infrastructure changes.

## Security Considerations

This module:

- Uses the TRANSFORMER role in Snowflake, which has the appropriate permissions
- Stores sensitive credentials securely
- Maintains the separation between RAW and ANALYTICS databases
- Enforces access control through Snowflake's role-based security

## Next Steps

After provisioning:

1. Set up your dbt project structure (if not already done)
2. Create models for your views and transformations
3. Set up documentation
4. Configure testing for data quality
