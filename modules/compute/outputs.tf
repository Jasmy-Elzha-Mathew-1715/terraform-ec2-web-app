# Output the security group ID for the web application
output "backend_security_group_id" {
  description = "ID of the web application security group"
  value       = aws_security_group.web_app_sg.id
}

# Output the ALB name
output "alb_name" {
  description = "Name of the Application Load Balancer"
  value       = aws_lb.web_alb.name
}

# Output the single web app instance ID (used as backend instance)
output "backend_instance_id" {
  description = "ID of the web application EC2 instance"
  value       = aws_instance.web_app.id
}

# Output the same instance ID for frontend (since it's the same instance)
output "frontend_instance_id" {
  description = "ID of the web application EC2 instance (same as backend)"
  value       = aws_instance.web_app.id
}

# Additional useful outputs
output "web_app_instance_id" {
  description = "ID of the web application EC2 instance"
  value       = aws_instance.web_app.id
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.web_alb.dns_name
}

output "alb_zone_id" {
  description = "Zone ID of the Application Load Balancer"
  value       = aws_lb.web_alb.zone_id
}

output "web_app_security_group_id" {
  description = "ID of the web application security group"
  value       = aws_security_group.web_app_sg.id
}

output "alb_security_group_id" {
  description = "ID of the ALB security group"
  value       = aws_security_group.alb_sg.id
}

output "frontend_target_group_arn" {
  description = "ARN of the frontend target group"
  value       = aws_lb_target_group.frontend_tg.arn
}

output "backend_target_group_arn" {
  description = "ARN of the backend target group"
  value       = aws_lb_target_group.backend_tg.arn
}