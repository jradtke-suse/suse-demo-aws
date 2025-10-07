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

variable "observability_instance_type" {
  description = "EC2 instance type for Observability server (minimum t3.xlarge for 10-nonha profile)"
  type        = string
  default     = "t3.xlarge"
}

variable "ami_id" {
  description = "AMI ID to use (leave empty to use latest SLES)"
  type        = string
  default     = ""
}

variable "observability_root_volume_size" {
  description = "Size of root volume in GB (minimum 280GB for 10-nonha profile)"
  type        = number
  default     = 300
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

variable "create_route53_record" {
  description = "Create Route53 DNS record for SUSE Observability"
  type        = bool
  default     = false
}

variable "root_domain" {
  description = "Root domain name (e.g., kubernerdes.com)"
  type        = string
  default     = "kubernerdes.com"
}

variable "subdomain" {
  description = "Environment subdomain (e.g., suse-demo-aws)"
  type        = string
  default     = "suse-demo-aws"
}

variable "hostname" {
  description = "Hostname for Observability service (e.g., observability). Creates hostname.subdomain.root_domain"
  type        = string
  default     = "observability"
}

variable "route53_zone_id" {
  description = "Route53 Hosted Zone ID (leave empty to auto-discover from subdomain.root_domain)"
  type        = string
  default     = ""
}

variable "suse_observability_license" {
  description = "SUSE Observability license key (required)"
  type        = string
  sensitive   = true
}

variable "suse_observability_base_url" {
  description = "Base URL for SUSE Observability (e.g., https://observability.example.com)"
  type        = string
}

variable "suse_rancher_url" {
  description = "Base URL for SUSE Rancher (e.g., https://rancher.example.com)"
  type        = string
}

variable "suse_observability_admin_password" {
  description = "Admin password for SUSE Observability (auto-generated if empty)"
  type        = string
  default     = ""
  sensitive   = true
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
