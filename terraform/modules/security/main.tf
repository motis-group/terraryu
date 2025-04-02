variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string
}

# IAM Role for Prefect
resource "aws_iam_role" "prefect_role" {
  name = "prefect-role-${var.environment}"

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

# IAM Policy for S3 access
resource "aws_iam_policy" "s3_access" {
  name        = "prefect-s3-access-${var.environment}"
  description = "Policy for Prefect to access S3 buckets"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket",
          "s3:DeleteObject"
        ]
        Effect = "Allow"
        Resource = [
          "arn:aws:s3:::data-platform-${var.environment}-data",
          "arn:aws:s3:::data-platform-${var.environment}-data/*"
        ]
      }
    ]
  })

  tags = {
    Environment = var.environment
  }
}

# Attach policies to role
resource "aws_iam_role_policy_attachment" "s3_access_attachment" {
  role       = aws_iam_role.prefect_role.name
  policy_arn = aws_iam_policy.s3_access.arn
}

# Security group for Prefect agents
resource "aws_security_group" "prefect_sg" {
  name        = "prefect-${var.environment}"
  description = "Security group for Prefect agents"

  # No ingress rules as agents only make outbound connections

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "prefect-${var.environment}"
    Environment = var.environment
  }
}

# Outputs
output "prefect_role_arn" {
  description = "ARN of the IAM role for Prefect"
  value       = aws_iam_role.prefect_role.arn
}

output "prefect_sg_id" {
  description = "ID of the security group for Prefect"
  value       = aws_security_group.prefect_sg.id
}
