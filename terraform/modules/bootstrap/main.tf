variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string
}

variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-west-2"
}

# KMS key for encrypting secrets
resource "aws_kms_key" "secrets_key" {
  description             = "KMS key for encrypting secrets in ${var.environment}"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  tags = {
    Environment = var.environment
    Name        = "secrets-key-${var.environment}"
  }
}

resource "aws_kms_alias" "secrets_key_alias" {
  name          = "alias/secrets-key-${var.environment}"
  target_key_id = aws_kms_key.secrets_key.key_id
}

# S3 bucket for Terraform state
resource "aws_s3_bucket" "terraform_state" {
  bucket = "data-platform-terraform-state-${var.environment}"

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Environment = var.environment
    Name        = "terraform-state-${var.environment}"
  }
}

resource "aws_s3_bucket_versioning" "terraform_state_versioning" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state_encryption" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.secrets_key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

# DynamoDB for Terraform state locking
resource "aws_dynamodb_table" "terraform_locks" {
  name         = "data-platform-terraform-locks-${var.environment}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Environment = var.environment
    Name        = "terraform-locks-${var.environment}"
  }
}

# AWS Secrets Manager for storing credentials
resource "aws_secretsmanager_secret" "platform_credentials" {
  name        = "data-platform/${var.environment}/credentials"
  description = "Credentials for the data platform in ${var.environment} environment"
  kms_key_id  = aws_kms_key.secrets_key.arn

  tags = {
    Environment = var.environment
  }
}

# Create an IAM role for Prefect to access secrets
resource "aws_iam_role" "prefect_secrets_role" {
  name = "prefect-secrets-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Environment = var.environment
  }
}

# Policy to allow Prefect to access the secrets
resource "aws_iam_policy" "prefect_secrets_policy" {
  name        = "prefect-secrets-policy-${var.environment}"
  description = "Policy to allow Prefect to access secrets in ${var.environment}"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
          "secretsmanager:ListSecrets"
        ]
        Effect   = "Allow"
        Resource = aws_secretsmanager_secret.platform_credentials.arn
      },
      {
        Action = [
          "kms:Decrypt"
        ]
        Effect   = "Allow"
        Resource = aws_kms_key.secrets_key.arn
      }
    ]
  })

  tags = {
    Environment = var.environment
  }
}

# Attach the policy to the role
resource "aws_iam_role_policy_attachment" "prefect_secrets_attachment" {
  role       = aws_iam_role.prefect_secrets_role.name
  policy_arn = aws_iam_policy.prefect_secrets_policy.arn
}

# Outputs
output "terraform_state_bucket" {
  description = "Name of the S3 bucket for Terraform state"
  value       = aws_s3_bucket.terraform_state.id
}

output "terraform_locks_table" {
  description = "Name of the DynamoDB table for Terraform locks"
  value       = aws_dynamodb_table.terraform_locks.id
}

output "secrets_key_arn" {
  description = "ARN of the KMS key for secrets"
  value       = aws_kms_key.secrets_key.arn
}

output "platform_credentials_secret_arn" {
  description = "ARN of the secrets manager secret for platform credentials"
  value       = aws_secretsmanager_secret.platform_credentials.arn
}

output "prefect_secrets_role_arn" {
  description = "ARN of the IAM role for Prefect to access secrets"
  value       = aws_iam_role.prefect_secrets_role.arn
} 
