output "cloudwatch_dashboard_url" {
  description = "URL to the CloudWatch dashboard"
  value       = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${aws_cloudwatch_dashboard.main.dashboard_name}"
}

output "sns_topic_arn" {
  description = "ARN of the SNS topic for alerts"
  value       = aws_sns_topic.alerts.arn
}

output "log_groups" {
  description = "Map of created CloudWatch log groups"
  value = {
    ec2  = aws_cloudwatch_log_group.ec2_logs.name
    rds  = aws_cloudwatch_log_group.rds_logs.name
    cicd = aws_cloudwatch_log_group.cicd_logs.name
  }
}