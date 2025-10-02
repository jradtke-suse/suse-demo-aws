# Shared Services

This Terraform project creates the common infrastructure needed for all SUSE demo products.

## Resources Created

- **VPC** - Isolated virtual network
- **Subnets** - Public and private subnets across multiple availability zones
- **Internet Gateway** - Provides internet access to public subnets
- **NAT Gateways** - Provides internet access to private subnets (optional, can be disabled to reduce costs)
- **Route Tables** - Routing configuration for subnets
- **Security Groups** - Firewall rules for:
  - SSH access
  - HTTP/HTTPS access
  - Internal VPC communication

## Configuration

1. Copy the example variables file:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

2. Edit `terraform.tfvars` and customize the values:
   - Set `owner` to your name
   - **IMPORTANT:** Update `allowed_ssh_cidr_blocks` and `allowed_web_cidr_blocks` to your IP address for security
   - Set `enable_nat_gateway = false` to reduce costs if private subnet internet access isn't required

## Deployment

```bash
terraform init
terraform plan
terraform apply
```

## Outputs

This module exports outputs that will be used by other projects:
- VPC ID and CIDR
- Subnet IDs (public and private)
- Security group IDs
- Availability zones

## Cost Optimization

To minimize costs for a demo environment:
- Set `enable_nat_gateway = false` in `terraform.tfvars` (saves ~$30-45/month per NAT gateway)
- Use only one availability zone if high availability isn't needed
- Remember to destroy resources when not in use: `terraform destroy`
