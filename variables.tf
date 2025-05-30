# variables.tf - Input variables for EC2-based Web Application

# General configuration
variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "web-app"
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1" # Change to your preferred region
}

# Networking
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnets" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnets" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.3.0/24", "10.0.4.0/24"]
}

# Compute
variable "backend_instance_type" {
  description = "EC2 instance type for backend server"
  type        = string
  default     = "t3.small"
}

variable "frontend_instance_type" {
  description = "EC2 instance type for frontend server"
  type        = string
  default     = "t3.small"
}

# Database
variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.small"
}

variable "db_name" {
  description = "Name of the PostgreSQL database"
  type        = string
  default     = "webappdb"
}

variable "db_username" {
  description = "Username for the PostgreSQL database"
  type        = string
  default     = "dbadmin"
  sensitive   = true
}

# CI/CD - GitHub
variable "github_owner" {
  description = "GitHub repository owner"
  type        = string
  default     = "your-github-username"
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
  default     = "terraform-ec2-web-app"
}

variable "github_branch" {
  description = "GitHub branch to watch for changes"
  type        = string
  default     = "main"
}

variable "github_token" {
  description = "GitHub personal access token"
  type        = string
  sensitive   = true
}

variable "webhook_secret" {
  description = "Secret for GitHub webhook"
  type        = string
  sensitive   = true
  default     = ""
}

# Other
variable "default_tags" {
  description = "Default tags for all resources"
  type        = map(string)
  default     = {}
}

variable "backend_ami_id" {
  description = "AMI ID for backend EC2 instance"
  type        = string
  # For a Node.js server, you could use an Amazon Linux 2 AMI
  default     = "ami-0c55b159cbfafe1f0" # This is an example - replace with actual AMI ID
}

variable "frontend_ami_id" {
  description = "AMI ID for frontend EC2 instance"
  type        = string
  # For an Angular frontend with Nginx, you could use an Amazon Linux 2 AMI
  default     = "ami-0c55b159cbfafe1f0" # This is an example - replace with actual AMI ID
}

variable "ssh_key_name" {
  description = "Name of the SSH key pair to use for EC2 instances"
  type        = string
  default     = "my-key-pair"  # The name you gave your key pair
}

variable "key_name" {
  description = "Name of the AWS key pair to use for EC2 instances"
  type        = string
  default     = null  # Optional: set to null if you don't want to require SSH access
  
  validation {
    condition = var.key_name == null || can(regex("^[a-zA-Z0-9][a-zA-Z0-9-_.]*$", var.key_name))
    error_message = "Key name must be a valid AWS key pair name or null."
  }
}

variable "admin_cidr_blocks" {
  description = "List of CIDR blocks that should have administrative access (SSH, etc.)"
  type        = list(string)
  default     = []  # Empty list means no admin access by default
  
  validation {
    condition = alltrue([
      for cidr in var.admin_cidr_blocks : can(cidrhost(cidr, 0))
    ])
    error_message = "All admin_cidr_blocks must be valid CIDR notation."
  }
}
