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
print_blue "  Setting up Data Platform Development Environment"
print_blue "========================================================"
echo ""

# Check for required tools
print_blue "Checking required tools..."

MISSING_TOOLS=0

if ! command_exists docker; then
  print_red "Docker is not installed. Please install Docker Desktop: https://www.docker.com/products/docker-desktop"
  MISSING_TOOLS=1
fi

if ! command_exists docker-compose; then
  print_red "Docker Compose is not installed. It usually comes with Docker Desktop."
  MISSING_TOOLS=1
fi

if ! command_exists python3; then
  print_red "Python 3 is not installed. Please install Python 3.8 or higher."
  MISSING_TOOLS=1
fi

if ! command_exists pip3; then
  print_red "pip3 is not installed. Please install pip for Python 3."
  MISSING_TOOLS=1
fi

if ! command_exists aws; then
  print_red "AWS CLI is not installed. Please install it: https://aws.amazon.com/cli/"
  MISSING_TOOLS=1
fi

if ! command_exists terraform; then
  print_red "Terraform is not installed. Please install it: https://www.terraform.io/downloads.html"
  MISSING_TOOLS=1
fi

if [ $MISSING_TOOLS -ne 0 ]; then
  print_red "Please install the missing tools and run this script again."
  exit 1
fi

print_green "All required tools are installed."
echo ""

# Create Python virtual environment
print_blue "Setting up Python virtual environment..."
if [ ! -d "venv" ]; then
  python3 -m venv venv
  print_green "Virtual environment created."
else
  print_green "Virtual environment already exists."
fi

# Source the virtual environment
if [[ "$OSTYPE" == "darwin"* ]] || [[ "$OSTYPE" == "linux-gnu"* ]]; then
  source venv/bin/activate
else
  source venv/Scripts/activate
fi

# Install Python dependencies
print_blue "Installing Python dependencies..."
pip install -r requirements.txt
print_green "Python dependencies installed."
echo ""

# Create .env file
print_blue "Setting up environment variables..."
if [ ! -f ".env" ]; then
  cp .env.example .env
  print_green ".env file created from .env.example."
  print_red "Please update the .env file with your credentials."
else
  print_green ".env file already exists."
fi
echo ""

# Start local development environment
print_blue "Starting local development environment..."
cd docker
docker-compose up -d
print_green "Local development environment started."
echo ""

# Initialize localstack
print_blue "Setting up localstack resources..."
sleep 5  # Wait for localstack to start

# Create S3 bucket in localstack
aws --endpoint-url=http://localhost:4566 s3 mb s3://data-platform-dev-data
print_green "S3 bucket created in localstack."

# Upload sample data
echo '{"id":1,"name":"test1","value":100}
{"id":2,"name":"test2","value":200}
{"id":3,"name":"test3","value":300}' > sample_data.json
aws --endpoint-url=http://localhost:4566 s3 cp sample_data.json s3://data-platform-dev-data/
print_green "Sample data uploaded to S3 bucket."
rm sample_data.json
echo ""

# Register Prefect blocks
print_blue "Registering Prefect blocks..."
cd ..
python -m prefect.blocks.storage
python -m prefect.blocks.secrets
print_green "Prefect blocks registered."
echo ""

# Explain credential management
print_blue "Credential Management:"
echo "  - Local development is using environment variables from .env file"
echo "  - In production, credentials are managed through AWS Secrets Manager"
echo "  - See docs/credential_management.md for more details"
echo ""

# Setup complete
print_blue "========================================================"
print_green "  Development environment setup complete!  "
print_blue "========================================================"
echo ""
print_blue "Local Prefect UI:    http://localhost:4200"
print_blue "Localstack S3:       http://localhost:4566"
echo ""
print_blue "To deploy a flow:"
echo "  prefect deployment build -a prefect/flows/data_ingestion/s3_to_snowflake.py:s3_to_snowflake_flow"
echo ""
print_blue "To start coding:"
echo "  1. Update the .env file with your credentials"
echo "  2. Activate the virtual environment: source venv/bin/activate"
echo "  3. Start developing your flows in the prefect/flows directory"
echo ""
print_blue "To shut down the environment:"
echo "  cd docker && docker-compose down"
echo ""
