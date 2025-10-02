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

output "neuvector_url" {
  description = "URL to access NeuVector"
  value       = "https://${var.create_eip ? aws_eip.security[0].public_ip : aws_instance.security.public_ip}:8443"
}

output "trivy_url" {
  description = "URL to access Trivy Server"
  value       = "http://${var.create_eip ? aws_eip.security[0].public_ip : aws_instance.security.public_ip}:8080"
}

output "security_group_id" {
  description = "ID of Security security group"
  value       = aws_security_group.security.id
}

output "ssh_command" {
  description = "SSH command to connect to instance"
  value       = var.ssh_public_key != "" ? "ssh ec2-user@${var.create_eip ? aws_eip.security[0].public_ip : aws_instance.security.public_ip}" : "Use AWS Systems Manager Session Manager to connect"
}
