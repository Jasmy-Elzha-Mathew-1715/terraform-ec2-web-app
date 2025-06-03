output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = aws_lb.web_alb.arn
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.web_alb.dns_name
}

output "alb_zone_id" {
  description = "Hosted zone ID of the Application Load Balancer"
  value       = aws_lb.web_alb.zone_id
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

output "http_listener_arn" {
  description = "ARN of the HTTP listener"
  value       = aws_lb_listener.http.arn
}