output "instance_id" {
  description = "ID of the Observability EC2 instance"
  value       = aws_instance.observability.id
}

output "private_ip" {
  description = "Private IP address of Observability instance"
  value       = aws_instance.observability.private_ip
}

output "public_ip" {
  description = "Public IP address of Observability instance"
  value       = var.create_eip ? aws_eip.observability[0].public_ip : aws_instance.observability.public_ip
}

output "grafana_url" {
  description = "URL to access Grafana"
  value       = "http://${var.create_eip ? aws_eip.observability[0].public_ip : aws_instance.observability.public_ip}:3000"
}

output "prometheus_url" {
  description = "URL to access Prometheus"
  value       = "http://${var.create_eip ? aws_eip.observability[0].public_ip : aws_instance.observability.public_ip}:9090"
}

output "alertmanager_url" {
  description = "URL to access AlertManager"
  value       = "http://${var.create_eip ? aws_eip.observability[0].public_ip : aws_instance.observability.public_ip}:9093"
}

output "security_group_id" {
  description = "ID of Observability security group"
  value       = aws_security_group.observability.id
}

output "ssh_command" {
  description = "SSH command to connect to instance"
  value       = var.ssh_public_key != "" ? "ssh ec2-user@${var.create_eip ? aws_eip.observability[0].public_ip : aws_instance.observability.public_ip}" : "Use AWS Systems Manager Session Manager to connect"
}
