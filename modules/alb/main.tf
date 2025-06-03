###############################################
# APPLICATION LOAD BALANCER MODULE  
###############################################

# Security group for the Application Load Balancer
resource "aws_security_group" "alb_sg" {
  name        = "${var.project_name}-alb-sg"
  description = "Security group for ALB"
  vpc_id      = var.vpc_id

  # Allow HTTP from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTP from anywhere"
  }

  # Allow HTTPS from anywhere
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTPS from anywhere"
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
    Name        = "${var.project_name}-alb-sg"
    Environment = var.environment
  }
}

# Application Load Balancer
resource "aws_lb" "web_alb" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = var.public_subnet_ids

  enable_deletion_protection = false

  tags = {
    Name        = "${var.project_name}-alb"
    Environment = var.environment
  }
}

# Target group for frontend (port 80)
resource "aws_lb_target_group" "frontend_tg" {
  name     = "${var.project_name}-frontend-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    enabled             = true
    interval            = 30
    path                = "/"
    port                = "traffic-port"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    matcher             = "200"
  }

  tags = {
    Name        = "${var.project_name}-frontend-tg"
    Environment = var.environment
  }
}

# Target group for backend API (port 3000 via nginx proxy)
resource "aws_lb_target_group" "backend_tg" {
  name     = "${var.project_name}-backend-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    enabled             = true
    interval            = 30
    path                = "/health"
    port                = "traffic-port"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    matcher             = "200"
  }

  tags = {
    Name        = "${var.project_name}-backend-tg"
    Environment = var.environment
  }
}

# Attach EC2 instance to frontend target group
resource "aws_lb_target_group_attachment" "frontend_attachment" {
  count            = length(var.target_instance_ids)
  target_group_arn = aws_lb_target_group.frontend_tg.arn
  target_id        = var.target_instance_ids[count.index]
  port             = 80
}

# Attach EC2 instance to backend target group
resource "aws_lb_target_group_attachment" "backend_attachment" {
  count            = length(var.target_instance_ids)
  target_group_arn = aws_lb_target_group.backend_tg.arn
  target_id        = var.target_instance_ids[count.index]
  port             = 80
}

# ALB listener for HTTP
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.web_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend_tg.arn
  }
}

# ALB listener rule for API path
resource "aws_lb_listener_rule" "api_rule" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend_tg.arn
  }

  condition {
    path_pattern {
      values = ["/api/*", "/health"]
    }
  }
}