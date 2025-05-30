# Variables for the compute module

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where resources will be created"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for ALB and EC2 instance"
  type        = list(string)
  validation {
    condition     = length(var.public_subnet_ids) >= 2
    error_message = "At least 2 public subnets are required for ALB."
  }
}

variable "instance_type" {
  description = "EC2 instance type for the web application server"
  type        = string
  default     = "t3.medium"
  validation {
    condition = contains([
      "t3.micro", "t3.small", "t3.medium", "t3.large",
      "t2.micro", "t2.small", "t2.medium", "t2.large",
      "m5.large", "m5.xlarge", "m5.2xlarge"
    ], var.instance_type)
    error_message = "Instance type must be a valid EC2 instance type."
  }
}

variable "key_name" {
  description = "Name of the AWS key pair for EC2 SSH access"
  type        = string
}

variable "admin_cidr_blocks" {
  description = "CIDR blocks allowed for SSH access"
  type        = list(string)
  default     = ["0.0.0.0/0"]
  validation {
    condition     = length(var.admin_cidr_blocks) > 0
    error_message = "At least one CIDR block must be specified for admin access."
  }
}

variable "artifacts_bucket_arn" {
  description = "ARN of the S3 bucket containing CI/CD artifacts"
  type        = string
}

variable "db_secret_arn" {
  description = "ARN of the Secrets Manager secret containing database credentials"
  type        = string
}

variable "aws_region" {
  description = "AWS region for CodeDeploy agent installation"
  type        = string
  default     = "us-east-1"
}

