output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.web_app.id
}

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.web_app.public_ip
}

output "instance_private_ip" {
  description = "Private IP address of the EC2 instance"
  value       = aws_instance.web_app.private_ip
}

output "security_group_id" {
  description = "ID of the web app security group"
  value       = aws_security_group.web_app_sg.id
}

output "iam_role_arn" {
  description = "ARN of the EC2 IAM role"
  value       = aws_iam_role.ec2_role.arn
}

output "iam_instance_profile_name" {
  description = "Name of the EC2 IAM instance profile"
  value       = aws_iam_instance_profile.ec2_profile.name
}