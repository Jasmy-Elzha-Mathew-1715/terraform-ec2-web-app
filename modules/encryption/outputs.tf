output "secret_arn" {
  description = "ARN of the secrets manager secret"
  value       = aws_secretsmanager_secret.db_secret.arn
}

output "secret_id" {
  description = "ID of the secrets manager secret"
  value       = aws_secretsmanager_secret.db_secret.id
}

output "secret_name" {
  description = "Name of the secrets manager secret"
  value       = aws_secretsmanager_secret.db_secret.name
}