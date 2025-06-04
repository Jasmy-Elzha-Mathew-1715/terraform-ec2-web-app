# outputs.tf - All infrastructure outputs

###############################################
# TERRAFORM STATE MANAGEMENT OUTPUTS
###############################################

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

output "bucket_name_pattern" {
  value       = "terraform-state-{project_name}-{environment}"
  description = "The naming pattern used for state buckets"
}

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

###############################################
# COMPUTE INFRASTRUCTURE OUTPUTS
###############################################

output "ec2_instance_id" {
  value       = module.compute.instance_id
  description = "ID of the EC2 instance"
}

output "ec2_instance_public_ip" {
  value       = module.compute.instance_public_ip
  description = "Public IP address of the EC2 instance"
}

output "security_group_id" {
  value       = module.compute.security_group_id
  description = "ID of the EC2 security group"
}

output "web_app_public_ip" {
  value = module.compute.instance_public_ip
}

###############################################
# LOAD BALANCER OUTPUTS
###############################################

output "alb_dns_name" {
  value       = module.alb.alb_dns_name
  description = "DNS name of the Application Load Balancer"
}

output "alb_arn" {
  value       = module.alb.alb_arn
  description = "ARN of the Application Load Balancer"
}

output "application_url" {
  value       = "http://${module.alb.alb_dns_name}"
  description = "URL to access the web application"
}

###############################################
# DATABASE OUTPUTS
###############################################

output "db_instance_id" {
  value       = module.database.db_instance_id
  description = "RDS instance ID"
}

output "db_instance_endpoint" {
  value       = module.database.db_instance_endpoint
  description = "RDS instance endpoint"
}

output "db_instance_address" {
  value       = module.database.db_instance_address
  description = "RDS instance address"
}

output "db_instance_port" {
  value       = module.database.db_instance_port
  description = "RDS instance port"
}

output "db_name" {
  value       = module.database.db_name
  description = "Database name"
}

###############################################
# ENCRYPTION/SECRETS OUTPUTS
###############################################

output "db_secret_arn" {
  value       = module.encryption.secret_arn
  description = "ARN of the database credentials secret"
}

output "db_secret_id" {
  value       = module.encryption.secret_id
  description = "ID of the database credentials secret"
}

output "db_secret_name" {
  value       = module.encryption.secret_name
  description = "Name of the database credentials secret"
}

###############################################
# NETWORKING OUTPUTS
###############################################

output "vpc_id" {
  value       = module.networking.vpc_id
  description = "ID of the VPC"
}

output "public_subnet_ids" {
  value       = module.networking.public_subnet_ids
  description = "IDs of the public subnets"
}

output "private_subnet_ids" {
  value       = module.networking.private_subnet_ids
  description = "IDs of the private subnets"
}

###############################################
# STORAGE OUTPUTS
###############################################

output "artifacts_bucket_id" {
  value       = module.storage.artifacts_bucket_id
  description = "ID of the CI/CD artifacts bucket"
}

output "artifacts_bucket_arn" {
  value       = module.storage.artifacts_bucket_arn
  description = "ARN of the CI/CD artifacts bucket"
}