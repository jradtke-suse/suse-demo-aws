output "instance_id" {
  description = "ID of the Rancher EC2 instance"
  value       = aws_instance.rancher.id
}

output "private_ip" {
  description = "Private IP address of Rancher instance"
  value       = aws_instance.rancher.private_ip
}

output "public_ip" {
  description = "Public IP address of Rancher instance"
  value       = var.create_eip ? aws_eip.rancher[0].public_ip : aws_instance.rancher.public_ip
}

output "rancher_url" {
  description = "URL to access Rancher"
  value       = var.create_route53_record && var.domain_name != "" ? "https://${var.rancher_subdomain}.${var.domain_name}" : "https://${var.create_eip ? aws_eip.rancher[0].public_ip : aws_instance.rancher.public_ip}"
}

output "rancher_hostname" {
  description = "Hostname used for Rancher installation"
  value       = local.rancher_fqdn
}

output "route53_record" {
  description = "Route53 DNS record created for Rancher (if enabled)"
  value       = var.create_route53_record && var.domain_name != "" ? "${var.rancher_subdomain}.${var.domain_name}" : "Not created - Route53 disabled"
}

output "security_group_id" {
  description = "ID of Rancher security group"
  value       = aws_security_group.rancher.id
}

output "ssh_command" {
  description = "SSH command to connect to instance"
  value       = var.ssh_public_key != "" ? "ssh -i suse-demo-aws.pem ec2-user@${var.create_eip ? aws_eip.rancher[0].public_ip : aws_instance.rancher.public_ip}" : "Use AWS Systems Manager Session Manager to connect"
}
