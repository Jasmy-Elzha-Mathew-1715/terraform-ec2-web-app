output "zone_id" {
  description = "ID of the Route53 zone"
  value       = aws_route53_zone.main.zone_id
}

output "domain_name" {
  description = "Domain name of the application"
  value       = var.domain_name
}

output "nameservers" {
  description = "Nameservers for the Route53 zone"
  value       = aws_route53_zone.main.name_servers
}

