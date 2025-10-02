output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of private subnets"
  value       = aws_subnet.private[*].id
}

output "public_subnet_cidrs" {
  description = "CIDR blocks of public subnets"
  value       = aws_subnet.public[*].cidr_block
}

output "private_subnet_cidrs" {
  description = "CIDR blocks of private subnets"
  value       = aws_subnet.private[*].cidr_block
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = aws_internet_gateway.main.id
}

output "nat_gateway_ids" {
  description = "IDs of NAT Gateways"
  value       = aws_nat_gateway.main[*].id
}

output "ssh_security_group_id" {
  description = "ID of SSH security group"
  value       = aws_security_group.ssh.id
}

output "https_security_group_id" {
  description = "ID of HTTPS security group"
  value       = aws_security_group.https.id
}

output "http_security_group_id" {
  description = "ID of HTTP security group"
  value       = aws_security_group.http.id
}

output "internal_security_group_id" {
  description = "ID of internal communication security group"
  value       = aws_security_group.internal.id
}

output "availability_zones" {
  description = "Availability zones used"
  value       = var.availability_zones
}
