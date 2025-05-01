variable "project_name" {
  description = "Name of the project used for resource naming"
  type        = string
}

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
}

variable "log_retention_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
  default     = 30
}

variable "backend_instance_id" {
  description = "Instance ID of the backend EC2 instance"
  type        = string
}

variable "frontend_instance_id" {
  description = "Instance ID of the frontend EC2 instance"
  type        = string
}

variable "db_instance_id" {
  description = "Instance ID of the RDS database"
  type        = string
}

variable "alb_name" {
  description = "Name of the Application Load Balancer"
  type        = string
}

variable "alert_emails" {
  description = "List of email addresses to receive CloudWatch alerts"
  type        = list(string)
  default     = []
}

