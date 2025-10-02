# SUSE Rancher Manager

This Terraform project deploys SUSE Rancher Manager on AWS.

## Overview

Rancher is deployed on a single EC2 instance running:
- SUSE Linux Enterprise Server (SLES)
- K3s (lightweight Kubernetes)
- Cert-manager (certificate management)
- Rancher Manager (Kubernetes management platform)

## Prerequisites

- Shared Services infrastructure must be deployed first
- SSH key pair for instance access (optional but recommended)

## Resources Created

- EC2 instance running Rancher Manager
- Security group for Rancher access (ports 80, 443, 6443)
- IAM role and instance profile
- Elastic IP (optional, enabled by default)
- Route53 DNS record (optional)

## Configuration

1. Copy the example variables file:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

2. Edit `terraform.tfvars`:
   - Set `owner` to your name
   - Add your SSH public key to `ssh_public_key`
   - **IMPORTANT:** Update `allowed_cidr_blocks` to your IP address
   - Adjust instance type if needed (t3.xlarge is minimum recommended)

### Route53 DNS Configuration (Optional)

To use a custom domain name instead of an IP address:

1. Ensure you have a Route53 hosted zone for your domain
2. In `terraform.tfvars`, set:
   ```hcl
   create_route53_record = true
   domain_name          = "example.com"
   rancher_subdomain    = "rancher"  # Creates rancher.example.com
   ```
3. (Optional) If you know your Route53 zone ID:
   ```hcl
   route53_zone_id = "Z1234567890ABC"
   ```
   Otherwise, it will be auto-discovered from `domain_name`

**Benefits of using Route53:**
- Stable DNS name (e.g., `rancher.example.com`)
- SSL certificates work properly with cert-manager
- Easier to remember and share access

## Deployment

```bash
terraform init
terraform plan
terraform apply
```

## Accessing Rancher

After deployment (wait ~10-15 minutes for installation to complete):

1. Get the Rancher URL from outputs:
   ```bash
   terraform output rancher_url
   ```

2. Access Rancher in your browser using the URL

3. Default credentials:
   - Username: `admin`
   - Password: `admin` (you'll be prompted to change this)

## Monitoring Installation

SSH into the instance and monitor the installation:

```bash
# Get SSH command
terraform output ssh_command

# Once connected, monitor the installation
sudo journalctl -u cloud-init-output -f

# Check Rancher pods
sudo kubectl --kubeconfig /etc/rancher/k3s/k3s.yaml get pods -n cattle-system
```

## Cost Optimization

- Default instance type is `t3.xlarge` (~$0.17/hour, ~$122/month)
- Set `create_eip = false` to avoid Elastic IP charges (~$3.60/month)
- Remember to destroy when not in use: `terraform destroy`

## Troubleshooting

If Rancher is not accessible:
1. Check instance is running: `aws ec2 describe-instances`
2. SSH to instance and check logs: `sudo journalctl -u cloud-init-output`
3. Verify Rancher pods are running: `sudo kubectl get pods -n cattle-system`
4. Check security group allows your IP address
5. If using Route53, verify DNS record was created:
   ```bash
   terraform output route53_record
   nslookup rancher.example.com
   ```
6. If DNS is configured but SSL fails, wait for cert-manager to issue certificates (~2-5 minutes)
