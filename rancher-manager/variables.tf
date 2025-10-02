variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-west-2"
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
  description = "EC2 instance type for Rancher server"
  type        = string
  default     = "t3.xlarge"
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
  description = "CIDR blocks allowed to access Rancher"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "create_eip" {
  description = "Create an Elastic IP for the Rancher instance"
  type        = bool
  default     = true
}

variable "rancher_version" {
  description = "Rancher version to install"
  type        = string
  default     = "2.9.2"
}

variable "cert_manager_version" {
  description = "Cert-manager version to install"
  type        = string
  default     = "1.15.3"
}

variable "rancher_hostname" {
  description = "Hostname for Rancher (leave empty to use default)"
  type        = string
  default     = ""
}

# Route53 DNS Configuration
variable "create_route53_record" {
  description = "Create Route53 DNS record for Rancher"
  type        = bool
  default     = false
}

variable "domain_name" {
  description = "Domain name for Route53 (e.g., example.com)"
  type        = string
  default     = ""
}

variable "rancher_subdomain" {
  description = "Subdomain for Rancher (e.g., rancher)"
  type        = string
  default     = "rancher"
}

variable "route53_zone_id" {
  description = "Route53 Hosted Zone ID (leave empty to auto-discover by domain name)"
  type        = string
  default     = ""
}
