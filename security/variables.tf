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

variable "security_instance_type" {
  description = "EC2 instance type for Security server"
  type        = string
  default     = "t3.large"
}

variable "ami_id" {
  description = "AMI ID to use (leave empty to use latest SLES)"
  type        = string
  default     = ""
}

variable "security_root_volume_size" {
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
  description = "CIDR blocks allowed to access Security services"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "create_eip" {
  description = "Create an Elastic IP for the Security instance"
  type        = bool
  default     = true
}

variable "neuvector_version" {
  description = "NeuVector version to install"
  type        = string
  default     = "5.3.4"
}

variable "suse_email" {
  description = "SUSE Email Address used to register to SCC"
  type        = string
  default     = ""
}

variable "suse_regcode" {
  description = "SUSE Registration Code used to register to SCC"
  type        = string
  default     = ""
}

variable "smt_url" {
  description = "SMT/RMT server URL (leave empty to use SUSE Customer Center)"
  type        = string
  default     = ""
}
