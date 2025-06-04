# outputs.tf for compute module

output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.web_app.id
}

output "instance_arn" {
  description = "ARN of the EC2 instance"
  value       = aws_instance.web_app.arn
}

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.web_app.public_ip
}

output "instance_private_ip" {
  description = "Private IP address of the EC2 instance"
  value       = aws_instance.web_app.private_ip
}

output "instance_public_dns" {
  description = "Public DNS name of the EC2 instance"
  value       = aws_instance.web_app.public_dns
}

output "instance_private_dns" {
  description = "Private DNS name of the EC2 instance"
  value       = aws_instance.web_app.private_dns
}

output "security_group_id" {
  description = "ID of the web app security group"
  value       = aws_security_group.web_app_sg.id
}

output "security_group_arn" {
  description = "ARN of the web app security group"
  value       = aws_security_group.web_app_sg.arn
}

output "instance_state" {
  description = "State of the EC2 instance"
  value       = aws_instance.web_app.instance_state
}

output "availability_zone" {
  description = "Availability zone of the EC2 instance"
  value       = aws_instance.web_app.availability_zone
}

output "key_name" {
  description = "Key pair name used by the EC2 instance"
  value       = aws_instance.web_app.key_name
}