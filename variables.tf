# variables.tf - All infrastructure variables

###############################################
# PROJECT AND ENVIRONMENT VARIABLES
###############################################

variable "project_name" {
  description = "Name of the project"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "Project name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "environment" {
  description = "Environment (e.g., dev, staging, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

###############################################
# NETWORKING VARIABLES
###############################################

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid IPv4 CIDR block."
  }
}

variable "public_subnets" {
  description = "List of public subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
  validation {
    condition     = length(var.public_subnets) >= 2
    error_message = "At least 2 public subnets are required for high availability."
  }
}

variable "private_subnets" {
  description = "List of private subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.20.0/24"]
  validation {
    condition     = length(var.private_subnets) >= 2
    error_message = "At least 2 private subnets are required for high availability."
  }
}

###############################################
# COMPUTE VARIABLES
###############################################

variable "backend_instance_type" {
  description = "EC2 instance type for backend server"
  type        = string
  default     = "t3.micro"
  validation {
    condition = contains([
      "t3.micro", "t3.small", "t3.medium", "t3.large",
      "t2.micro", "t2.small", "t2.medium", "t2.large",
      "m5.large", "m5.xlarge", "c5.large", "c5.xlarge"
    ], var.backend_instance_type)
    error_message = "Instance type must be a valid EC2 instance type."
  }
}

variable "key_name" {
  description = "Name of the AWS key pair for EC2 access"
  type        = string
  default     = "my-key-pair"
}

variable "admin_cidr_blocks" {
  description = "List of CIDR blocks allowed for SSH access"
  type        = list(string)
  default     = ["0.0.0.0/0"]
  validation {
    condition = alltrue([
      for cidr in var.admin_cidr_blocks : can(cidrhost(cidr, 0))
    ])
    error_message = "All CIDR blocks must be valid IPv4 CIDR blocks."
  }
}

###############################################
# DATABASE VARIABLES
###############################################

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
  validation {
    condition = contains([
      "db.t3.micro", "db.t3.small", "db.t3.medium", "db.t3.large",
      "db.t2.micro", "db.t2.small", "db.t2.medium", "db.t2.large",
      "db.m5.large", "db.m5.xlarge", "db.r5.large", "db.r5.xlarge"
    ], var.db_instance_class)
    error_message = "Database instance class must be a valid RDS instance type."
  }
}

variable "db_allocated_storage" {
  description = "Allocated storage for the database (GB)"
  type        = number
  default     = 20
  validation {
    condition     = var.db_allocated_storage >= 20 && var.db_allocated_storage <= 65536
    error_message = "Database storage must be between 20 GB and 65536 GB."
  }
}

variable "db_name" {
  description = "Name of the database"
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9_]*$", var.db_name))
    error_message = "Database name must start with a letter and contain only letters, numbers, and underscores."
  }
}

variable "db_username" {
  description = "Database master username"
  type        = string
  default     = "postgres"
  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9_]*$", var.db_username))
    error_message = "Database username must start with a letter and contain only letters, numbers, and underscores."
  }
}

variable "db_password" {
  description = "Database master password"
  type        = string
  sensitive   = true
}

variable "db_multi_az" {
  description = "Enable Multi-AZ deployment for high availability"
  type        = bool
  default     = false
}

variable "db_backup_retention_period" {
  description = "Backup retention period in days"
  type        = number
  default     = 7
  validation {
    condition     = var.db_backup_retention_period >= 0 && var.db_backup_retention_period <= 35
    error_message = "Backup retention period must be between 0 and 35 days."
  }
}

###############################################
# CI/CD VARIABLES
###############################################

variable "webhook_secret" {
  description = "Secret for GitHub webhook validation"
  type        = string
  sensitive   = true
  validation {
    condition     = length(var.webhook_secret) >= 8
    error_message = "Webhook secret must be at least 8 characters long."
  }
}

variable "github_owner" {
  description = "GitHub repository owner/organization"
  type        = string
  validation {
    condition     = length(var.github_owner) > 0
    error_message = "GitHub owner cannot be empty."
  }
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
  validation {
    condition     = length(var.github_repo) > 0
    error_message = "GitHub repository name cannot be empty."
  }
}

variable "github_branch" {
  description = "GitHub branch to track for CI/CD"
  type        = string
  default     = "main"
  validation {
    condition     = length(var.github_branch) > 0
    error_message = "GitHub branch cannot be empty."
  }
}

variable "github_token" {
  description = "GitHub personal access token for repository access"
  type        = string
  sensitive   = true
  validation {
    condition     = length(var.github_token) > 0
    error_message = "GitHub token cannot be empty."
  }
}

###############################################
# OPTIONAL FEATURE FLAGS
###############################################

variable "enable_monitoring" {
  description = "Enable CloudWatch monitoring and alarms"
  type        = bool
  default     = true
}

variable "enable_backup" {
  description = "Enable automated database backups"
  type        = bool
  default     = true
}

variable "enable_encryption" {
  description = "Enable encryption at rest for database and storage"
  type        = bool
  default     = true
}

###############################################
# ENVIRONMENT-SPECIFIC OVERRIDES
###############################################

variable "production_settings" {
  description = "Production-specific settings override"
  type = object({
    instance_type         = optional(string, "t3.small")
    db_instance_class     = optional(string, "db.t3.small")
    db_multi_az          = optional(bool, true)
    backup_retention     = optional(number, 30)
    deletion_protection  = optional(bool, true)
  })
  default = {}
}

variable "development_settings" {
  description = "Development-specific settings override"
  type = object({
    instance_type         = optional(string, "t3.micro")
    db_instance_class     = optional(string, "db.t3.micro")
    db_multi_az          = optional(bool, false)
    backup_retention     = optional(number, 1)
    deletion_protection  = optional(bool, false)
  })
  default = {}
}

###############################################
# TAGS VARIABLES
###############################################

variable "additional_tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
  validation {
    condition = alltrue([
      for key, value in var.additional_tags : 
      length(key) <= 128 && length(value) <= 256
    ])
    error_message = "Tag keys must be <= 128 characters and values <= 256 characters."
  }
}