output "artifacts_bucket_name" {
  description = "The name of the S3 bucket for CI/CD artifacts"
  value       = aws_s3_bucket.cicd_artifacts.bucket
}

output "artifacts_bucket_arn" {
  description = "The ARN of the S3 bucket for CI/CD artifacts"
  value       = aws_s3_bucket.cicd_artifacts.arn
}

output "artifacts_bucket_id" {
  description = "The ID of the S3 bucket for CI/CD artifacts"
  value       = aws_s3_bucket.cicd_artifacts.id
}