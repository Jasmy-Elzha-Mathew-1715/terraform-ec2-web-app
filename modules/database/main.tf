###############################################
# RDS POSTGRESQL DATABASE RESOURCES
###############################################

# Security group for RDS PostgreSQL
resource "aws_security_group" "rds_sg" {
  name        = "${var.project_name}-rds-sg"
  description = "Security group for RDS PostgreSQL"
  vpc_id      = var.vpc_id

  # Allow PostgreSQL access from backend instances
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [var.backend_sg_id]
    description     = "Allow PostgreSQL from backend app"
  }

  # Allow outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name        = "${var.project_name}-rds-sg"
    Environment = var.environment
  }
}

# Random password generation for RDS
resource "random_password" "db_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# DB Subnet Group
resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "${var.project_name}-rds-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name        = "${var.project_name}-rds-subnet-group"
    Environment = var.environment
  }
}

# RDS Parameter Group
resource "aws_db_parameter_group" "postgres" {
  name        = "${var.project_name}-${var.environment}-postgres-params"
  family      = "postgres17"
  description = "Parameter group for ${var.project_name} PostgreSQL"

  parameter {
    name  = "log_connections"
    value = "1"
  }

  parameter {
    name  = "log_disconnections"
    value = "1"
  }

  parameter {
    name  = "log_statement"
    value = "ddl"
  }

  tags = {
    Name        = "${var.project_name}-postgres-params"
    Environment = var.environment
  }
}

# RDS PostgreSQL Instance
resource "aws_db_instance" "postgres" {
  identifier              = "${var.project_name}-${var.environment}-postgres"
  engine                  = "postgres"
  engine_version          = "17.1"
  instance_class          = var.db_instance_class
  allocated_storage       = var.db_allocated_storage
  storage_type            = "gp2"
  db_name                 = var.db_name
  username                = var.db_username
  password                = random_password.db_password.result
  port                    = 5432
  vpc_security_group_ids  = [aws_security_group.rds_sg.id]
  db_subnet_group_name    = aws_db_subnet_group.rds_subnet_group.name
  publicly_accessible     = false
  multi_az                = var.db_multi_az
  backup_retention_period = var.db_backup_retention_period
  backup_window           = "03:00-04:00"
  maintenance_window      = "Mon:04:00-Mon:05:00"
  skip_final_snapshot     = var.environment != "prod"
  final_snapshot_identifier = var.environment == "prod" ? "${var.project_name}-${var.environment}-postgres-final-snapshot" : null
  deletion_protection     = var.environment == "prod"
  storage_encrypted       = true
  parameter_group_name    = aws_db_parameter_group.postgres.name

  tags = {
    Name        = "${var.project_name}-postgres"
    Environment = var.environment
  }

  lifecycle {
    prevent_destroy = false
  }
}