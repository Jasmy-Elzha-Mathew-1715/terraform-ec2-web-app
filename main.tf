# main.tf - Main entry point for EC2-based Web Application

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"  # Or newer
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
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

# Generate a random suffix for the S3 bucket
resource "random_id" "bucket_suffix" {
  byte_length = 8
}

# Create S3 bucket for Terraform state
resource "aws_s3_bucket" "terraform_state" {
  bucket = "terraform-state-${var.project_name}-${random_id.bucket_suffix.hex}"

  # Force destroy allows the bucket to be destroyed even with content
  force_destroy = true

  tags = {
    Name = "Terraform State"
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

# Local state backend initially, can be switched to S3 after first apply
# For S3 backend, you'll need to comment this out, run terraform init & apply,
# then uncomment it and run terraform init with -backend-config options
terraform {
  backend "local" {}
  # backend "s3" {
  #   key     = "terraform-ec2-web-app/terraform.tfstate"
  #   region  = "us-east-1"
  #   encrypt = true
  # }
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

# Compute Module - EC2 Instances, Application Load Balancer
module "compute" {
  source = "./modules/compute"

  project_name      = var.project_name
  environment       = var.environment
  vpc_id            = module.networking.vpc_id
  public_subnet_ids = module.networking.public_subnet_ids
  aws_region        = var.aws_region
  db_secret_arn     = module.database.db_secret_arn
  artifacts_bucket_arn = module.storage.artifacts_bucket_arn
  
  backend_instance_type  = var.backend_instance_type
  frontend_instance_type = var.frontend_instance_type
  backend_ami_id         = var.backend_ami_id
  frontend_ami_id        = var.frontend_ami_id
}

# Database Module - RDS PostgreSQL
module "database" {
  source = "./modules/database"

  project_name      = var.project_name
  environment       = var.environment
  vpc_id            = module.networking.vpc_id
  private_subnet_ids = module.networking.private_subnet_ids
  backend_sg_id     = module.compute.backend_security_group_id
  
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

# Output the name of the generated S3 bucket for reference
output "terraform_state_bucket" {
  value       = aws_s3_bucket.terraform_state.bucket
  description = "The name of the S3 bucket used for Terraform state storage"
}