# variables.tf for compute module

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where resources will be created"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for EC2 placement"
  type        = list(string)
}

variable "alb_security_group_ids" {
  description = "List of ALB security group IDs that can access the EC2 instance"
  type        = list(string)
}

variable "admin_cidr_blocks" {
  description = "CIDR blocks allowed for SSH access to EC2 instance"
  type        = list(string)
  default     = []
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.medium"
}

variable "key_name" {
  description = "EC2 Key Pair name for SSH access"
  type        = string
}

variable "aws_region" {
  description = "AWS region for CodeDeploy agent installation"
  type        = string
}

variable "iam_instance_profile_name" {
  description = "Name of the IAM instance profile to attach to EC2 instance"
  type        = string
  default     = null
}