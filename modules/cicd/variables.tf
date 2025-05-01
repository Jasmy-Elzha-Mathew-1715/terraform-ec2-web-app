variable "project_name" {
  description = "The name of the project"
  type        = string
}

variable "environment" {
  description = "The deployment environment (e.g., dev, staging, prod)"
  type        = string
}

variable "artifacts_bucket_id" {
  description = "The ID of the S3 bucket for CI/CD artifacts"
  type        = string
}

variable "artifacts_bucket_arn" {
  description = "The ARN of the S3 bucket for CI/CD artifacts"
  type        = string
}

variable "github_owner" {
  description = "The GitHub owner (username or organization)"
  type        = string
}

variable "github_repo" {
  description = "The GitHub repository name"
  type        = string
}

variable "github_branch" {
  description = "The GitHub branch to monitor for changes"
  type        = string
  default     = "main"
}

variable "github_token" {
  description = "The GitHub OAuth token"
  type        = string
  sensitive   = true
}

variable "webhook_secret" {
  description = "Secret token for GitHub webhook"
  type        = string
  sensitive   = true
}

