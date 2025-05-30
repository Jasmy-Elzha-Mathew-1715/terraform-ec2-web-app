# main.tf - Main entry point for EC2-based Web Application

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"  # Or newer
    }
    null = {
      source  = "hashicorp/null"  
      version = "~> 3.0"
    }
  }
}

# Configure AWS Provider
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

# Create S3 bucket with predictable naming pattern for API integration
resource "aws_s3_bucket" "terraform_state" {
  bucket = "terraform-state-${var.project_name}-${var.environment}"

  # Force destroy allows the bucket to be destroyed even with content
  force_destroy = true

  tags = {
    Name        = "Terraform State Storage"
    Purpose     = "API-managed"
    Template    = var.project_name
    Environment = var.environment
  }
}

# Enable versioning on the S3 bucket
resource "aws_s3_bucket_versioning" "terraform_state_versioning" {
  bucket = aws_s3_bucket.terraform_state.id
  
  versioning_configuration {
    status = "Enabled"
  }
}

# Enable server-side encryption for the S3 bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state_encryption" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block public access to the state bucket
resource "aws_s3_bucket_public_access_block" "terraform_state_pab" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Use local backend initially - this allows the API to manage state files
terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}

# Data source to get current AWS account ID and region for consistent naming
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Local values for consistent naming across resources
locals {
  # Create a consistent bucket name pattern that your API can predict
  state_bucket_name = "terraform-state-${var.project_name}-${var.environment}"
  
  # Common tags applied to all resources
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    AccountId   = data.aws_caller_identity.current.account_id
    Region      = data.aws_region.current.name
  }
}

# Networking Module - VPC, Subnets, Internet Gateway, NAT Gateway
module "networking" {
  source = "./modules/networking"

  project_name    = var.project_name
  environment     = var.environment
  vpc_cidr        = var.vpc_cidr
  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets
}

# Compute Module - Single EC2 Instance with ALB
module "compute" {
  source = "./modules/compute"

  project_name         = var.project_name
  environment          = var.environment
  vpc_id               = module.networking.vpc_id
  public_subnet_ids    = module.networking.public_subnet_ids
  aws_region           = var.aws_region
  db_secret_arn        = module.database.db_secret_arn
  artifacts_bucket_arn = module.storage.artifacts_bucket_arn
  
  instance_type     = var.backend_instance_type
  key_name         = var.key_name
  admin_cidr_blocks = var.admin_cidr_blocks
}

# Database Module - RDS PostgreSQL
module "database" {
  source = "./modules/database"

  project_name       = var.project_name
  environment        = var.environment
  vpc_id             = module.networking.vpc_id
  private_subnet_ids = module.networking.private_subnet_ids
  backend_sg_id      = module.compute.backend_security_group_id
  
  db_instance_class = var.db_instance_class
  db_name           = var.db_name
  db_username       = var.db_username
}

# Storage Module - S3 for CI/CD artifacts
module "storage" {
  source = "./modules/storage"

  project_name = var.project_name
  environment  = var.environment
}

# CI/CD Module - CodePipeline, CodeBuild, CodeDeploy (using GitHub instead of CodeCommit)
module "cicd" {
  source = "./modules/cicd"

  project_name         = var.project_name
  environment          = var.environment
  artifacts_bucket_arn = module.storage.artifacts_bucket_arn
  webhook_secret       = var.webhook_secret
  
  # GitHub settings
  github_owner         = var.github_owner
  github_repo          = var.github_repo
  github_branch        = var.github_branch
  github_token         = var.github_token
  
  # Build and deployment settings
  artifacts_bucket_id  = module.storage.artifacts_bucket_id
}

# Monitoring Module - CloudWatch
module "monitoring" {
  source = "./modules/monitoring"

  project_name        = var.project_name
  db_instance_id      = module.database.db_instance_id
  alb_name            = module.compute.alb_name
  aws_region          = var.aws_region
  backend_instance_id = module.compute.backend_instance_id
  frontend_instance_id = module.compute.frontend_instance_id
}

# Outputs for API integration
output "terraform_state_bucket" {
  value       = aws_s3_bucket.terraform_state.bucket
  description = "The name of the S3 bucket used for Terraform state storage"
}

output "terraform_state_bucket_arn" {
  value       = aws_s3_bucket.terraform_state.arn
  description = "The ARN of the S3 bucket used for Terraform state storage"
}

output "terraform_state_bucket_region" {
  value       = aws_s3_bucket.terraform_state.region
  description = "The region of the S3 bucket used for Terraform state storage"
}

# Output the predictable bucket name pattern for API reference
output "bucket_name_pattern" {
  value       = "terraform-state-{project_name}-{environment}"
  description = "The naming pattern used for state buckets"
}

# Output current configuration for debugging
output "current_config" {
  value = {
    project_name    = var.project_name
    environment     = var.environment
    aws_region      = var.aws_region
    account_id      = data.aws_caller_identity.current.account_id
    bucket_name     = local.state_bucket_name
  }
  description = "Current configuration details for debugging"
}