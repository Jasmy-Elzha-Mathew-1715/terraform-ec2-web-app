# outputs.tf - Output variables for EC2-based Web Application

# Networking outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.networking.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.networking.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.networking.private_subnet_ids
}

# Compute outputs
output "backend_instance_id" {
  description = "ID of the backend EC2 instance"
  value       = module.compute.backend_instance_id
}

output "frontend_instance_id" {
  description = "ID of the frontend EC2 instance"
  value       = module.compute.frontend_instance_id
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = module.compute.alb_dns_name
}

# Database outputs
output "db_endpoint" {
  description = "Endpoint of the RDS instance"
  value       = module.database.db_endpoint
}

output "db_instance_id" {
  description = "ID of the RDS instance"
  value       = module.database.db_instance_id
}

# Storage outputs
output "artifacts_bucket_name" {
  description = "Name of the S3 bucket for CI/CD artifacts"
  value       = module.storage.artifacts_bucket_name
}

# Application URL
output "application_url" {
  description = "URL of the deployed application"
  value       = "http://${module.compute.alb_dns_name}"
}

output "api_url" {
  description = "URL of the API endpoint"
  value       = "http://${module.compute.alb_dns_name}/api"
}