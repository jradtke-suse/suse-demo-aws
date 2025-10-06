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

# Route53 DNS Configuration
variable "create_route53_record" {
  description = "Create Route53 DNS record for Rancher"
  type        = bool
  default     = false
}

variable "root_domain" {
  description = "Root domain name (e.g., kubernerdes.com)"
  type        = string
  default     = ""
}

variable "subdomain" {
  description = "Environment subdomain (e.g., suse-demo-aws)"
  type        = string
  default     = ""
}

variable "hostname" {
  description = "Hostname for Rancher service (e.g., rancher). Creates hostname.subdomain.root_domain"
  type        = string
  default     = "rancher"
}

variable "route53_zone_id" {
  description = "Route53 Hosted Zone ID (leave empty to auto-discover from subdomain.root_domain)"
  type        = string
  default     = ""
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
