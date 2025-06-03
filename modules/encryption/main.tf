###############################################
# AWS SECRETS MANAGER RESOURCES
###############################################

# AWS Secrets Manager for RDS credentials
resource "aws_secretsmanager_secret" "db_secret" {
  name = "${var.project_name}-${var.environment}-db-secret-${formatdate("YYMMDDhhmmss", timestamp())}"
  description = "RDS PostgreSQL credentials for ${var.project_name} ${var.environment}"

  tags = {
    Name        = "${var.project_name}-db-credentials"
    Environment = var.environment
  }
}

# Store credentials in Secrets Manager (simplified - no dynamic DB info)
resource "aws_secretsmanager_secret_version" "db_secret_version" {
  secret_id = aws_secretsmanager_secret.db_secret.id
  secret_string = jsonencode({
    username = var.db_username
    password = var.db_password
    engine   = "postgres"
    dbname   = var.db_name
  })
}

# Data source to read the secret (for other resources to use)
data "aws_secretsmanager_secret_version" "db_secret" {
  secret_id = aws_secretsmanager_secret.db_secret.id
  depends_on = [aws_secretsmanager_secret_version.db_secret_version]
}