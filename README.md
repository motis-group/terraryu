# Data Platform

A robust, scalable data platform built with Prefect, Terraform, AWS, and Snowflake.

## Architecture

This data platform implements a modern architecture that separates infrastructure as code from workflow definitions:

- **Infrastructure as Code**: Terraform manages all cloud resources across environments
- **Workflow Orchestration**: Prefect handles workflow scheduling, monitoring, and execution
- **Data Storage**: AWS S3 for object storage and Snowflake for data warehousing
- **Local Development**: Docker Compose for local development parity

## Project Structure

```
data-platform/
│
├── terraform/                      # Infrastructure as code
│   ├── environments/               # Environment-specific configurations
│   ├── modules/                    # Reusable infrastructure components
│   └── main.tf                     # Main Terraform configuration
│
├── prefect/                        # Prefect workflows
│   ├── flows/                      # Task orchestration flows
│   ├── tasks/                      # Reusable task definitions
│   ├── blocks/                     # Prefect infrastructure blocks
│   └── deployments/                # Deployment configurations
│
├── docker/                         # Containerization
│   ├── prefect-agent/              # Prefect agent container
│   ├── flow-runner/                # Flow execution container
│   └── docker-compose.yml          # Local development environment
│
├── scripts/                        # Utility scripts
│   └── setup_environment.sh        # New developer onboarding script
│
├── .github/                        # GitHub integration
│   └── workflows/                  # GitHub Actions CI/CD pipelines
│
└── .env.example                    # Template for environment variables
```

## Getting Started

### Prerequisites

- Docker and Docker Compose
- Python 3.8+
- AWS CLI
- Terraform
- Make

### Local Development Setup

1. Clone the repository:

   ```bash
   git clone https://github.com/yourusername/data-platform.git
   cd data-platform
   ```

2. Run the setup script:

   ```bash
   ./scripts/setup_environment.sh
   ```

3. This script will:

   - Set up a Python virtual environment
   - Install dependencies
   - Create a local `.env` file
   - Start the local development environment using Docker Compose
   - Initialize Prefect blocks

4. Access the local Prefect UI at http://localhost:4200

### Environment Variables

Copy the `.env.example` file to `.env` and fill in your credentials:

```
# AWS Credentials
AWS_ACCESS_KEY_ID=your_access_key
AWS_SECRET_ACCESS_KEY=your_secret_key

# Snowflake Credentials
SNOWFLAKE_ACCOUNT=your_account
SNOWFLAKE_USER=your_user
SNOWFLAKE_PASSWORD=your_password
```

## Workflow Development

### Creating a New Flow

1. Create a new Python file in `prefect/flows/your_directory/your_flow.py`
2. Use the Prefect `@flow` and `@task` decorators to define your workflow
3. Add configuration to `prefect/deployments/your_env.yaml`

### Testing Flows Locally

```bash
# Run a flow directly
python -m prefect.flows.data_ingestion.s3_to_snowflake

# Deploy a flow from a YAML file
prefect deployment apply prefect/deployments/dev.yaml
```

## Infrastructure Management

### Creating Resources

1. Update Terraform modules and configurations as needed
2. Apply changes to a specific environment:

```bash
cd terraform
terraform init -backend-config="bucket=data-platform-terraform-state-dev" -backend-config="key=terraform.tfstate" -backend-config="region=us-west-2"
terraform plan -var-file="environments/dev.tfvars" -out=tfplan
terraform apply tfplan
```

### Environment Management

Each environment (dev, staging, prod) has its own Terraform variable files and Prefect deployment configurations. This ensures proper isolation between environments.

## CI/CD Pipelines

This project includes GitHub Actions workflows for:

- Terraform planning and validation
- Terraform infrastructure application
- Prefect flow deployment

## Contributing

1. Create a new branch for your feature
2. Make your changes, ensuring all tests pass
3. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.
