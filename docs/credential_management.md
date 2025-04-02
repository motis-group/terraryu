# Credential Management

This document describes how the data platform manages credentials to prevent circular dependencies.

## The Circular Dependency Problem

The classic circular dependency with credentials looks like:

- You need credentials to create infrastructure with Terraform
- You want to store credentials in that infrastructure (like AWS Secrets Manager)
- But you need those credentials to create the infrastructure in the first place

## Our Solution: Two-Phase Approach

We implement a two-phase approach to break this circular dependency:

### Phase 1: Bootstrap (Manual, One-Time)

1. Use local credentials (environment variables) for initial setup
2. Create minimal infrastructure for credential storage using the bootstrap module
3. Store the permanent credentials in AWS Secrets Manager

```bash
# Example command to bootstrap the infrastructure
cd terraform/00-bootstrap
terraform init
terraform apply -var="environment=dev"

# After bootstrap resources are created, update secrets manually
aws secretsmanager update-secret --secret-id data-platform/dev/credentials --secret-string '{
  "SNOWFLAKE_ACCOUNT": "your-account",
  "SNOWFLAKE_USER": "your-user",
  "SNOWFLAKE_PASSWORD": "your-password",
  "SNOWFLAKE_WAREHOUSE": "your-warehouse",
  "SNOWFLAKE_DATABASE": "your-database",
  "SNOWFLAKE_SCHEMA": "your-schema",
  "SNOWFLAKE_ROLE": "your-role"
}'
```

### Phase 2: Regular Operations (Automated)

1. Update the backend configuration to use the created S3 bucket and DynamoDB table
2. Use IAM roles for accessing the credentials in AWS Secrets Manager
3. CI/CD has read-only access to the bootstrap secrets
4. Local development uses developer-specific credentials or temporary roles

```bash
# Example command to deploy regular infrastructure after bootstrap
cd terraform
terraform init \
  -backend-config="bucket=data-platform-terraform-state-dev" \
  -backend-config="key=terraform.tfstate" \
  -backend-config="region=us-west-2" \
  -backend-config="dynamodb_table=data-platform-terraform-locks-dev"
terraform apply -var-file="environments/dev.tfvars"
```

## Credential Access in Prefect Flows

Our platform provides a flexible `SecretManager` class that implements a fallback chain:

1. First, try to access secrets from AWS Secrets Manager
2. If that fails, try to load Prefect Secret blocks
3. If that fails, try to get the value from environment variables

This approach ensures that:

- In production, credentials are fetched securely from AWS Secrets Manager
- In development, developers can use local environment variables
- Flows are portable between environments

Example usage in a Prefect flow:

```python
from prefect.blocks.secrets import SecretManager

# Create a secret manager for the current environment
secret_manager = SecretManager(environment="dev")

# Get a secret with the fallback chain
password = secret_manager.get_secret("SNOWFLAKE_PASSWORD")
```

## IAM Role-Based Authentication

In production environments, we use IAM roles instead of hard-coded credentials:

1. ECS tasks run with an IAM role that has permission to access the necessary secrets
2. The Prefect flow uses the ECS task's IAM role to authenticate with AWS services
3. No AWS credentials are passed to the flow - it inherits them from the execution environment

This approach:

- Eliminates the need to pass credentials to flows
- Follows the principle of least privilege
- Leverages AWS's built-in security mechanisms

## Local Development

For local development, we provide multiple options:

1. Use local environment variables stored in a `.env` file
2. Assume an IAM role with appropriate permissions
3. Use the setup script to register Prefect blocks with credentials

The setup script (`scripts/setup_environment.sh`) automatically configures the local environment based on the `.env` file.

## Separating Infrastructure Management from Flow Execution

To maintain separation of concerns:

1. Terraform creates and manages the credential storage (AWS Secrets Manager)
2. A bootstrap phase initializes this storage with initial credentials
3. Subsequent infrastructure deployments and Prefect flows access these credentials using IAM roles
4. Local development uses a separate credential path to avoid dependencies on production infrastructure

This separation ensures that:

- The platform can be deployed to a new environment without circular dependencies
- Credential rotation doesn't require infrastructure redeployment
- Local development is independent of production credential management
