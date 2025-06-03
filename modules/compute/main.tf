###############################################
# EC2 INSTANCE MODULE
###############################################

# Security group for the web application EC2 instance
resource "aws_security_group" "web_app_sg" {
  name        = "${var.project_name}-web-app-sg"
  description = "Security group for web app (Node.js backend + Angular frontend)"
  vpc_id      = var.vpc_id

  # Allow HTTP from ALB (frontend)
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = var.alb_security_group_ids
    description     = "Allow HTTP from ALB for frontend"
  }

  # Allow Node.js backend port from ALB
  ingress {
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = var.alb_security_group_ids
    description     = "Allow backend API access from ALB"
  }

  # Allow SSH access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.admin_cidr_blocks
    description = "Allow SSH from admin IPs"
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name        = "${var.project_name}-web-app-sg"
    Environment = var.environment
  }
}

# IAM role for EC2 instances
resource "aws_iam_role" "ec2_role" {
  name = "${var.project_name}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    Name        = "${var.project_name}-ec2-role"
    Environment = var.environment
  }
}

# IAM profile for EC2 instances
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.project_name}-ec2-profile"
  role = aws_iam_role.ec2_role.name
}

# IAM policy for EC2 to access S3 and other services
resource "aws_iam_role_policy" "ec2_policy" {
  name = "${var.project_name}-ec2-policy"
  role = aws_iam_role.ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:ListBucket",
        ]
        Effect   = "Allow"
        Resource = [
          var.artifacts_bucket_arn,
          "${var.artifacts_bucket_arn}/*"
        ]
      },
      {
        Action = [
          "secretsmanager:GetSecretValue",
        ]
        Effect   = "Allow"
        Resource = var.db_secret_arn
      },
      {
        Action = [
          "cloudwatch:PutMetricData",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

# Single EC2 instance hosting both Node.js backend and Angular frontend
resource "aws_instance" "web_app" {
  ami                    = "ami-0f88e80871fd81e91"
  instance_type          = var.instance_type
  subnet_id              = var.public_subnet_ids[0]
  vpc_security_group_ids = [aws_security_group.web_app_sg.id]
  key_name               = var.key_name
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name

  user_data = <<-EOF
    #!/bin/bash
    echo "Setting up full-stack web application server"
    
    # Install system dependencies
    apt-get update
    apt-get install -y nginx git build-essential

    # Install Node.js 16.x
    curl -sL https://deb.nodesource.com/setup_16.x | sudo -E bash -
    apt-get install -y nodejs

    # Configure Nginx for Angular frontend and Node.js backend proxy
    cat <<'NGINX_CONF' > /etc/nginx/sites-available/default
    server {
        listen 80 default_server;
        listen [::]:80 default_server;

        root /var/www/html;
        index index.html;

        server_name _;

        # Serve Angular frontend
        location / {
            try_files $$uri $$uri/ /index.html;
        }

        # Proxy API requests to Node.js backend
        location /api/ {
            proxy_pass http://localhost:3000/api/;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $$http_upgrade;
            proxy_set_header Connection 'upgrade';
            proxy_set_header Host $$host;
            proxy_set_header X-Real-IP $$remote_addr;
            proxy_set_header X-Forwarded-For $$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $$scheme;
            proxy_cache_bypass $$http_upgrade;
        }

        # Health check endpoint for ALB
        location /health {
            proxy_pass http://localhost:3000/health;
            proxy_http_version 1.1;
            proxy_set_header Host $$host;
        }
    }
    NGINX_CONF

    # Create application directory
    mkdir -p /opt/webapp
    chown ubuntu:ubuntu /opt/webapp

    # Setup CodeDeploy agent
    apt-get install -y ruby wget
    cd /home/ubuntu
    wget https://aws-codedeploy-${var.aws_region}.s3.amazonaws.com/latest/install
    chmod +x ./install
    ./install auto
    service codedeploy-agent start

    # Create systemd service for Node.js backend
    cat <<'SERVICE_CONF' > /etc/systemd/system/webapp-backend.service
    [Unit]
    Description=Node.js Web Application Backend
    After=network.target

    [Service]
    Type=simple
    User=ubuntu
    WorkingDirectory=/opt/webapp
    ExecStart=/usr/bin/node server.js
    Restart=on-failure
    Environment=NODE_ENV=production
    Environment=PORT=3000

    [Install]
    WantedBy=multi-user.target
    SERVICE_CONF

    # Enable and start services
    systemctl daemon-reload
    systemctl enable nginx
    systemctl enable webapp-backend
    systemctl restart nginx
    
    # Create a placeholder health endpoint
    mkdir -p /opt/webapp
    cat <<'HEALTH_JS' > /opt/webapp/server.js
    const express = require('express');
    const app = express();
    const port = 3000;

    app.get('/health', (req, res) => {
      res.json({ status: 'ok', message: 'Backend is running' });
    });

    app.get('/api/health', (req, res) => {
      res.json({ status: 'ok', message: 'API is running' });
    });

    app.listen(port, () => {
      console.log('Backend server running on port ' + port);
    });
    HEALTH_JS

    # Install basic Express for health check
    cd /opt/webapp
    npm init -y
    npm install express
    chown -R ubuntu:ubuntu /opt/webapp

    # Start the backend service
    systemctl start webapp-backend
    
    echo "Full-stack web application setup completed"
  EOF

  tags = {
    Name        = "${var.project_name}-web-app"
    Environment = var.environment
    Role        = "fullstack"
  }

  # Ensure proper termination settings
  root_block_device {
    volume_type           = "gp2"
    volume_size           = 30
    delete_on_termination = true
  }

  volume_tags = {
    Name        = "${var.project_name}-web-app-volume"
    Environment = var.environment
  }

  lifecycle {
    create_before_destroy = true
  }
}