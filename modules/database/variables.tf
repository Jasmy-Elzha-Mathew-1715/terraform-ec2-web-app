variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Deployment environment (e.g., dev, test, prod)"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "private_subnet_ids" {
  description = "IDs of the private subnets"
  type        = list(string)
}

variable "backend_sg_id" {
  description = "ID of the backend security group"
  type        = string
}

variable "db_name" {
  description = "Name of the database"
  type        = string
  default     = "app_db"
}

variable "db_username" {
  description = "Username for the database"
  type        = string
  default     = "app_user"
}

variable "db_password" {
  description = "Password for the database"
  type        = string
  default     = "app_user"
}

variable "db_engine_version" {
  description = "Version of PostgreSQL to use"
  type        = string
  default     = "14.6"
}

variable "db_instance_class" {
  description = "Instance class for the RDS instance"
  type        = string
  default     = "db.t3.small"
}

variable "db_allocated_storage" {
  description = "Allocated storage for the RDS instance in GB"
  type        = number
  default     = 20
}

variable "db_multi_az" {
  description = "Whether to enable Multi-AZ for the RDS instance"
  type        = bool
  default     = false
}

variable "db_backup_retention_period" {
  description = "Number of days to retain backups"
  type        = number
  default     = 7
}