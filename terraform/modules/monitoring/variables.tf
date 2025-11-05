# Monitoring Module - Variables

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "alarm_email_addresses" {
  description = "Email addresses for alarm notifications"
  type        = list(string)
  default     = []
}

variable "alb_arn_suffix" {
  description = "ARN suffix of the Application Load Balancer"
  type        = string
  default     = ""
}

variable "target_group_arn_suffix" {
  description = "ARN suffix of the Target Group"
  type        = string
  default     = ""
}

variable "db_instance_id" {
  description = "ID of the RDS instance"
  type        = string
  default     = ""
}

variable "db_connections_threshold" {
  description = "Threshold for database connections alarm"
  type        = number
  default     = 80
}

variable "application_log_group_name" {
  description = "Name of the application CloudWatch log group"
  type        = string
  default     = "/aws/application/logs"
}

variable "enable_cost_budget" {
  description = "Enable AWS Budget for cost monitoring"
  type        = bool
  default     = false
}

variable "monthly_budget_limit" {
  description = "Monthly budget limit in USD"
  type        = string
  default     = "100"
}

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}
