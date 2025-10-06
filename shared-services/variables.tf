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

variable "enable_nat_gateway" {
  description = "Boolean whether to deploy NATGW (future use)"
  type        = bool  
  default     = false
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "az_count" {
  description = "Number of availability zones to use (1-6)"
  type        = number
  default     = 3

  validation {
    condition     = var.az_count >= 1 && var.az_count <= 6
    error_message = "The az_count must be between 1 and 6."
  }

  validation {
    condition     = var.az_count <= length(var.availability_zones)
    error_message = "The az_count cannot exceed the number of availability zones specified in the availability_zones variable."
  }
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
