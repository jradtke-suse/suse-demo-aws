variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-2"
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "demo"
}

variable "owner" {
  description = "Owner tag for resources"
  type        = string
  default     = "suse-demo"
}

variable "instance_type" {
  description = "EC2 instance type for Observability server"
  type        = string
  default     = "t3.large"
}

variable "ami_id" {
  description = "AMI ID to use (leave empty to use latest SLES)"
  type        = string
  default     = ""
}

variable "root_volume_size" {
  description = "Size of root volume in GB"
  type        = number
  default     = 100
}

variable "ssh_public_key" {
  description = "SSH public key for instance access"
  type        = string
  default     = ""
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to access Observability services"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "create_eip" {
  description = "Create an Elastic IP for the Observability instance"
  type        = bool
  default     = true
}

variable "grafana_admin_password" {
  description = "Admin password for Grafana"
  type        = string
  default     = "admin"
  sensitive   = true
}
