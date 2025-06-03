variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where resources will be created"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs"
  type        = list(string)
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "EC2 Key Pair name for SSH access"
  type        = string
}

variable "admin_cidr_blocks" {
  description = "CIDR blocks allowed for SSH access"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "artifacts_bucket_arn" {
  description = "ARN of the S3 bucket containing deployment artifacts"
  type        = string
}

variable "db_secret_arn" {
  description = "ARN of the database secret in AWS Secrets Manager"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "alb_security_group_ids" {
  description = "List of ALB security group IDs that can access this EC2 instance"
  type        = list(string)
}