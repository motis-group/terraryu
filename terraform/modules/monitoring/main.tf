variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string
}

# CloudWatch Log Group for Prefect
resource "aws_cloudwatch_log_group" "prefect_logs" {
  name              = "/prefect/${var.environment}"
  retention_in_days = 30

  tags = {
    Environment = var.environment
    Service     = "prefect"
  }
}

# CloudWatch Dashboard for Prefect
resource "aws_cloudwatch_dashboard" "prefect_dashboard" {
  dashboard_name = "prefect-${var.environment}"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ECS", "CPUUtilization", "ServiceName", "prefect-agent", "ClusterName", "prefect-${var.environment}"]
          ]
          period = 300
          stat   = "Average"
          region = "us-west-2"
          title  = "Prefect Agent CPU"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ECS", "MemoryUtilization", "ServiceName", "prefect-agent", "ClusterName", "prefect-${var.environment}"]
          ]
          period = 300
          stat   = "Average"
          region = "us-west-2"
          title  = "Prefect Agent Memory"
        }
      }
    ]
  })
}

# CloudWatch Alarm for high CPU usage
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "prefect-${var.environment}-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "This metric monitors high cpu utilization for Prefect agents"

  dimensions = {
    ClusterName = "prefect-${var.environment}"
    ServiceName = "prefect-agent"
  }

  alarm_actions = [] # Add SNS topic ARN here for notifications
  ok_actions    = [] # Add SNS topic ARN here for notifications
}

# Outputs
output "log_group_name" {
  description = "Name of the CloudWatch log group for Prefect"
  value       = aws_cloudwatch_log_group.prefect_logs.name
}

output "dashboard_name" {
  description = "Name of the CloudWatch dashboard for Prefect"
  value       = aws_cloudwatch_dashboard.prefect_dashboard.dashboard_name
}
