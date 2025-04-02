#!/bin/bash
set -e

# Print colored text
print_green() {
  echo -e "\e[32m$1\e[0m"
}

print_blue() {
  echo -e "\e[34m$1\e[0m"
}

print_red() {
  echo -e "\e[31m$1\e[0m"
}

# Function to check if a command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Welcome message
print_blue "========================================================"
print_blue "  Bootstrapping Data Platform Environment"
print_blue "========================================================"
echo ""

# Get environment from command line
ENV=${1:-dev}
print_blue "Target environment: $ENV"
echo ""

# Check for required tools
print_blue "Checking required tools..."

MISSING_TOOLS=0

if ! command_exists terraform; then
  print_red "Terraform is not installed. Please install it: https://www.terraform.io/downloads.html"
  MISSING_TOOLS=1
fi

if ! command_exists aws; then
  print_red "AWS CLI is not installed. Please install it: https://aws.amazon.com/cli/"
  MISSING_TOOLS=1
fi

if [ $MISSING_TOOLS -ne 0 ]; then
  print_red "Please install the missing tools and run this script again."
  exit 1
fi

print_green "All required tools are installed."
echo ""

# Verify AWS credentials
print_blue "Checking AWS credentials..."
if ! aws sts get-caller-identity > /dev/null 2>&1; then
  print_red "AWS credentials not configured. Please run 'aws configure' first."
  exit 1
fi
print_green "AWS credentials verified."
echo ""

# Step 1: Apply bootstrap Terraform
print_blue "Step 1: Applying bootstrap Terraform configuration..."
cd "$(dirname "$0")/../terraform/00-bootstrap"

terraform init
terraform apply -var="environment=$ENV" -auto-approve

# Get outputs for later use
TERRAFORM_STATE_BUCKET=$(terraform output -raw terraform_state_bucket)
TERRAFORM_LOCKS_TABLE=$(terraform output -raw terraform_locks_table)
SECRETS_ARN=$(terraform output -raw platform_credentials_secret_arn)

print_green "Bootstrap infrastructure created successfully."
echo "Terraform State Bucket: $TERRAFORM_STATE_BUCKET"
echo "Terraform Locks Table: $TERRAFORM_LOCKS_TABLE"
echo "Secrets ARN: $SECRETS_ARN"
echo ""

# Step 2: Update Secrets
print_blue "Step 2: Updating credentials in AWS Secrets Manager..."
echo "Please provide the credentials for your environment:"

read -p "Snowflake Account: " SNOWFLAKE_ACCOUNT
read -p "Snowflake User: " SNOWFLAKE_USER
read -sp "Snowflake Password: " SNOWFLAKE_PASSWORD
echo ""
read -p "Snowflake Warehouse (default: COMPUTE_WH): " SNOWFLAKE_WAREHOUSE
SNOWFLAKE_WAREHOUSE=${SNOWFLAKE_WAREHOUSE:-COMPUTE_WH}
read -p "Snowflake Database (default: DATA_DB): " SNOWFLAKE_DATABASE
SNOWFLAKE_DATABASE=${SNOWFLAKE_DATABASE:-DATA_DB}
read -p "Snowflake Schema (default: PUBLIC): " SNOWFLAKE_SCHEMA
SNOWFLAKE_SCHEMA=${SNOWFLAKE_SCHEMA:-PUBLIC}
read -p "Snowflake Role (default: ACCOUNTADMIN): " SNOWFLAKE_ROLE
SNOWFLAKE_ROLE=${SNOWFLAKE_ROLE:-ACCOUNTADMIN}

# Create JSON for the secret
SECRET_JSON=$(cat <<EOF
{
  "SNOWFLAKE_ACCOUNT": "$SNOWFLAKE_ACCOUNT",
  "SNOWFLAKE_USER": "$SNOWFLAKE_USER",
  "SNOWFLAKE_PASSWORD": "$SNOWFLAKE_PASSWORD",
  "SNOWFLAKE_WAREHOUSE": "$SNOWFLAKE_WAREHOUSE",
  "SNOWFLAKE_DATABASE": "$SNOWFLAKE_DATABASE",
  "SNOWFLAKE_SCHEMA": "$SNOWFLAKE_SCHEMA",
  "SNOWFLAKE_ROLE": "$SNOWFLAKE_ROLE"
}
EOF
)

# Update the secret in AWS Secrets Manager
aws secretsmanager update-secret --secret-id "$SECRETS_ARN" --secret-string "$SECRET_JSON"

print_green "Credentials updated in AWS Secrets Manager."
echo ""

# Step 3: Configure main terraform backend
print_blue "Step 3: Configuring main Terraform backend..."
cd "$(dirname "$0")/../terraform"
cat > backend.conf <<EOF
bucket         = "$TERRAFORM_STATE_BUCKET"
key            = "terraform.tfstate"
region         = "us-west-2"
dynamodb_table = "$TERRAFORM_LOCKS_TABLE"
EOF

print_green "Backend configuration created at terraform/backend.conf"
echo ""

print_blue "========================================================"
print_green "  Environment $ENV bootstrapped successfully!"
print_blue "========================================================"
echo ""
print_blue "Next steps:"
echo "1. Initialize the main Terraform configuration with the backend:"
echo "   cd terraform"
echo "   terraform init -backend-config=backend.conf"
echo ""
echo "2. Apply the main Terraform configuration:"
echo "   terraform apply -var-file=\"environments/$ENV.tfvars\""
echo ""

print_blue "For more information about credential management, see:"
echo "docs/credential_management.md"
echo "" 