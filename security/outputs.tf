output "instance_id" {
  description = "ID of the Security EC2 instance"
  value       = aws_instance.security.id
}

output "private_ip" {
  description = "Private IP address of Security instance"
  value       = aws_instance.security.private_ip
}

output "public_ip" {
  description = "Public IP address of Security instance"
  value       = var.create_eip ? aws_eip.security[0].public_ip : aws_instance.security.public_ip
}

output "fqdn" {
  description = "Fully qualified domain name for SUSE Security"
  value       = var.create_route53_record && var.subdomain != "" && var.root_domain != "" ? local.security_fqdn : null
}

output "route53_record" {
  description = "Route53 DNS record (if created)"
  value = var.create_route53_record && var.subdomain != "" && var.root_domain != "" ? {
    fqdn    = "${var.hostname_security}.${var.subdomain}.${var.root_domain}"
    zone_id = local.zone_id
    type    = "A"
    value   = var.create_eip ? aws_eip.security[0].public_ip : aws_instance.security.public_ip
  } : null
}

output "neuvector_url" {
  description = "URL to access NeuVector"
  value       = var.create_route53_record && var.subdomain != "" && var.root_domain != "" ? "https://${var.hostname_security}.${var.subdomain}.${var.root_domain}:8443" : "https://${var.create_eip ? aws_eip.security[0].public_ip : aws_instance.security.public_ip}:8443"
}

output "trivy_url" {
  description = "URL to access Trivy Server"
  value       = var.create_route53_record && var.subdomain != "" && var.root_domain != "" ? "http://${var.hostname_security}.${var.subdomain}.${var.root_domain}:8080" : "http://${var.create_eip ? aws_eip.security[0].public_ip : aws_instance.security.public_ip}:8080"
}

output "security_group_id" {
  description = "ID of Security security group"
  value       = aws_security_group.security.id
}

output "ssh_command" {
  description = "SSH command to connect to instance"
  value       = var.ssh_public_key != "" ? "ssh ec2-user@${var.create_eip ? aws_eip.security[0].public_ip : aws_instance.security.public_ip}" : "Use AWS Systems Manager Session Manager to connect"
}
