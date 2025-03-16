variable "project" {
  type        = string
  description = "Project name used for resource naming"
}

variable "env_name" {
  type        = string
  description = "Environment name (e.g., DEV, TEST, PROD)"
}

variable "time_travel_in_days" {
  type        = number
  description = "Number of days for time travel feature"
  default     = 1
}

variable "admin_password" {
  description = "Password for admin user"
  type        = string
  sensitive   = true
}

variable "stitch_password" {
  description = "Password for Stitch integration user"
  type        = string
  sensitive   = true
}

variable "fivetran_password" {
  description = "Password for Fivetran integration user"
  type        = string
  sensitive   = true
}

variable "dbt_cloud_password" {
  description = "Password for dbt Cloud user"
  type        = string
  sensitive   = true
}

variable "mode_password" {
  description = "Password for Mode Analytics user"
  type        = string
  sensitive   = true
}

variable "looker_password" {
  description = "Password for Looker user"
  type        = string
  sensitive   = true
}

variable "analyst_jane_password" {
  description = "Password for Analyst Jane"
  type        = string
  sensitive   = true
}

variable "analyst_john_password" {
  description = "Password for Analyst John"
  type        = string
  sensitive   = true
}