terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = var.environment
      Project     = "suse-demo"
      Component   = "security"
      ManagedBy   = "terraform"
      Owner       = var.owner
    }
  }
}

# Data source to get shared services outputs
data "terraform_remote_state" "shared" {
  backend = "local"

  config = {
    path = "${path.module}/../shared-services/terraform.tfstate"
  }
}

# Get latest SLES AMI
data "aws_ami" "sles" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["suse-sles-15-sp*-v*-hvm-ssd-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Security Group for SUSE Security
resource "aws_security_group" "security" {
  name_prefix = "${var.environment}-suse-security-"
  description = "Security group for SUSE Security"
  vpc_id      = data.terraform_remote_state.shared.outputs.vpc_id

  # NeuVector UI
  ingress {
    description = "NeuVector UI"
    from_port   = 8443
    to_port     = 8443
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  # Trivy Server
  ingress {
    description = "Trivy Server"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  # HTTP/HTTPS
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.environment}-suse-security-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# IAM Role for Security
resource "aws_iam_role" "security" {
  name_prefix = "${var.environment}-suse-security-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.environment}-suse-security-role"
  }
}

# IAM Instance Profile
resource "aws_iam_instance_profile" "security" {
  name_prefix = "${var.environment}-suse-security-"
  role        = aws_iam_role.security.name
}

# Attach SSM policy for remote management
resource "aws_iam_role_policy_attachment" "security_ssm" {
  role       = aws_iam_role.security.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Key Pair
resource "aws_key_pair" "security" {
  count      = var.ssh_public_key != "" ? 1 : 0
  key_name   = "${var.environment}-suse-security-key"
  public_key = var.ssh_public_key

  tags = {
    Name = "${var.environment}-suse-security-key"
  }
}

# EC2 Instance for SUSE Security
resource "aws_instance" "security" {
  ami                    = var.ami_id != "" ? var.ami_id : data.aws_ami.sles.id
  instance_type          = var.instance_type
  subnet_id              = data.terraform_remote_state.shared.outputs.public_subnet_ids[0]
  key_name               = var.ssh_public_key != "" ? aws_key_pair.security[0].key_name : null
  iam_instance_profile   = aws_iam_instance_profile.security.name
  vpc_security_group_ids = [
    aws_security_group.security.id,
    data.terraform_remote_state.shared.outputs.ssh_security_group_id,
    data.terraform_remote_state.shared.outputs.internal_security_group_id
  ]

  root_block_device {
    volume_size           = var.root_volume_size
    volume_type           = "gp3"
    delete_on_termination = true
    encrypted             = true
  }

  user_data = templatefile("${path.module}/user-data.sh", {
    neuvector_version = var.neuvector_version
    suse_email        = var.suse_email
    suse_regcode      = var.suse_regcode
    smt_url           = var.smt_url
  })

  tags = {
    Name = "${var.environment}-suse-security"
  }
}

# Elastic IP for Security
resource "aws_eip" "security" {
  count    = var.create_eip ? 1 : 0
  instance = aws_instance.security.id
  domain   = "vpc"

  tags = {
    Name = "${var.environment}-suse-security-eip"
  }
}
