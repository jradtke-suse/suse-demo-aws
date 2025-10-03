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

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones to use"
  type        = list(string)
  default     = ["us-east-2a", "us-east-2b", "us-east-2c"]
}

variable "allowed_ssh_cidr_blocks" {
  description = "CIDR blocks allowed to SSH to instances"
  type        = list(string)
  default     = ["0.0.0.0/0"] # Change this to your IP for better security
}

variable "allowed_web_cidr_blocks" {
  description = "CIDR blocks allowed to access web interfaces"
  type        = list(string)
  default     = ["0.0.0.0/0"] # Change this to your IP for better security
}
