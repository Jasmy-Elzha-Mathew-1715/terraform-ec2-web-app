variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Deployment environment (e.g., dev, test, prod)"
  type        = string
}

variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "public_subnet_ids" {
  description = "IDs of the public subnets"
  type        = list(string)
}

variable "key_name" {
  description = "Name of the SSH key pair"
  type        = string
  default     = null
}

variable "backend_ami_id" {
  description = "AMI ID for the backend instance"
  type        = string
}

variable "backend_instance_type" {
  description = "Instance type for the backend"
  type        = string
  default     = "t2.micro"
}

variable "frontend_ami_id" {
  description = "AMI ID for the frontend instance"
  type        = string
}

variable "frontend_instance_type" {
  description = "Instance type for the frontend"
  type        = string
  default     = "t2.micro"
}

variable "admin_cidr_blocks" {
  description = "CIDR blocks that can access the instances via SSH"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "dns_zone_id" {
  description = "Route53 zone ID for DNS records (optional)"
  type        = string
  default     = ""  # Empty default makes it optional
}

variable "domain_name" {
  description = "Domain name for the application (optional)"
  type        = string
  default     = ""  # Empty default makes it optional
}

variable "artifacts_bucket_arn" {
  description = "ARN of the S3 bucket storing CI/CD artifacts"
  type        = string
}

variable "db_secret_arn" {
  description = "ARN of the Secrets Manager secret for DB credentials"
  type        = string
}