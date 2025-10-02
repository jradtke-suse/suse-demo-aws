# SUSE Security

This Terraform project deploys a comprehensive security stack on AWS.

## Overview

The security stack includes:
- **NeuVector** - Kubernetes-native container security platform
- **Trivy** - Vulnerability scanner for containers and other artifacts
- **Falco** - Runtime security and threat detection

All components run on a single EC2 instance with SUSE Linux Enterprise Server (SLES) and K3s.

## Prerequisites

- Shared Services infrastructure must be deployed first
- SSH key pair for instance access (optional but recommended)

## Resources Created

- EC2 instance running the security stack
- Security group for access (ports 8443, 8080)
- IAM role and instance profile
- Elastic IP (optional, enabled by default)

## Configuration

1. Copy the example variables file:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

2. Edit `terraform.tfvars`:
   - Set `owner` to your name
   - Add your SSH public key to `ssh_public_key`
   - **IMPORTANT:** Update `allowed_cidr_blocks` to your IP address

## Deployment

```bash
terraform init
terraform plan
terraform apply
```

## Accessing Security Tools

After deployment (wait ~10-15 minutes for installation to complete):

### NeuVector (Container Security)
```bash
terraform output neuvector_url
```
- Default credentials: `admin` / `admin`
- Change password on first login
- Features:
  - Container vulnerability scanning
  - Network security policies
  - Runtime protection
  - Compliance reporting

### Trivy (Vulnerability Scanner)
```bash
terraform output trivy_url
```

Scan container images:
```bash
# From your local machine (replace IP with output)
trivy image --server http://IP:8080 nginx:latest

# From the instance
ssh to instance
trivy image nginx:latest
```

### Falco (Runtime Security)

Falco runs as a systemd service and monitors system calls for suspicious activity.

View Falco alerts:
```bash
# SSH to instance
terraform output ssh_command

# View Falco logs
sudo journalctl -u falco -f
```

## Using NeuVector

### Scanning Images
1. Access NeuVector UI
2. Go to Assets → Registries
3. Add your container registry
4. Scan images for vulnerabilities

### Network Policies
1. Go to Policy → Network Rules
2. Create network segmentation rules
3. Monitor and block unauthorized traffic

### Runtime Protection
1. Go to Policy → Groups
2. Enable runtime protection modes:
   - Discover: Learning mode
   - Monitor: Alert on violations
   - Protect: Block violations

## Using Trivy

### Scan Container Images
```bash
trivy image nginx:latest
trivy image --severity HIGH,CRITICAL myapp:v1.0
```

### Scan Filesystem
```bash
trivy fs /path/to/project
```

### Scan Kubernetes Cluster
```bash
trivy k8s --report summary
```

## Integration with Rancher

To integrate with Rancher Manager:

1. In Rancher, go to Cluster Management
2. Select your cluster
3. Go to Apps → Charts
4. Install NeuVector from Rancher chart repository
5. Configure to use this instance as the central manager

## Monitoring Installation

SSH into the instance:

```bash
# Get SSH command
terraform output ssh_command

# Check K3s
sudo kubectl get nodes
sudo kubectl get pods -n neuvector

# Check services
sudo systemctl status trivy-server
sudo systemctl status falco

# View installation logs
sudo journalctl -u cloud-init-output -f
```

## Cost Optimization

- Default instance type is `t3.large` (~$0.08/hour, ~$58/month)
- Set `create_eip = false` to avoid Elastic IP charges (~$3.60/month)
- Remember to destroy when not in use: `terraform destroy`

## Security Best Practices

1. **Restrict Access**: Update `allowed_cidr_blocks` to your IP only
2. **Change Passwords**: Change NeuVector admin password immediately
3. **Enable MFA**: Configure multi-factor authentication in NeuVector
4. **Review Policies**: Regularly review and update security policies
5. **Monitor Alerts**: Set up notifications for Falco and NeuVector alerts

## Troubleshooting

If services are not accessible:
1. Check instance is running: `aws ec2 describe-instances`
2. SSH to instance and check logs: `sudo journalctl -u cloud-init-output`
3. Verify K3s is running: `sudo kubectl get nodes`
4. Check NeuVector pods: `sudo kubectl get pods -n neuvector`
5. Verify services: `sudo systemctl status trivy-server falco`
6. Check security group allows your IP address
