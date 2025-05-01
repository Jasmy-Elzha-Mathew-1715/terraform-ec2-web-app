output "backend_instance_id" {
  description = "ID of the backend EC2 instance"
  value       = aws_instance.backend.id
}

output "backend_instance_private_ip" {
  description = "Private IP of the backend EC2 instance"
  value       = aws_instance.backend.private_ip
}

output "frontend_instance_id" {
  description = "ID of the frontend EC2 instance"
  value       = aws_instance.frontend.id
}

output "frontend_instance_private_ip" {
  description = "Private IP of the frontend EC2 instance"
  value       = aws_instance.frontend.private_ip
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.web_alb.dns_name
}

output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = aws_lb.web_alb.arn
}

output "alb_security_group_id" {
  description = "ID of the security group for the ALB"
  value       = aws_security_group.alb_sg.id
}

output "backend_security_group_id" {
  description = "ID of the security group for the backend instance"
  value       = aws_security_group.backend_sg.id
}

output "frontend_security_group_id" {
  description = "ID of the security group for the frontend instance"
  value       = aws_security_group.frontend_sg.id
}

output "ec2_iam_role_arn" {
  description = "ARN of the IAM role for EC2 instances"
  value       = aws_iam_role.ec2_role.arn
}

output "ec2_iam_role_name" {
  description = "Name of the IAM role for EC2 instances"
  value       = aws_iam_role.ec2_role.name
}

output "application_url" {
  description = "The URL for the web application"
  value       = "http://${var.domain_name}"
}

output "alb_name" {
  description = "Name of the Application Load Balancer"
  value       = aws_lb.main.name
}

output "alb_zone_id" {
  description = "Canonical hosted zone ID of the Application Load Balancer"
  value       = aws_lb.main.zone_id
}