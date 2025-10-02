# SUSE Observability

This Terraform project deploys a complete observability stack on AWS.

## Overview

The observability stack includes:
- **Prometheus** - Metrics collection and time-series database
- **Grafana** - Visualization and dashboards
- **AlertManager** - Alert handling and notifications
- **Node Exporter** - System metrics collection

All components run on a single EC2 instance with SUSE Linux Enterprise Server (SLES).

## Prerequisites

- Shared Services infrastructure must be deployed first
- SSH key pair for instance access (optional but recommended)

## Resources Created

- EC2 instance running the observability stack
- Security group for access (ports 3000, 9090, 9093)
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
   - **IMPORTANT:** Change `grafana_admin_password` from default

## Deployment

```bash
terraform init
terraform plan
terraform apply
```

## Accessing the Observability Stack

After deployment (wait ~5 minutes for installation to complete):

### Grafana (Visualization)
```bash
terraform output grafana_url
```
- Default credentials: `admin` / password from `grafana_admin_password`

### Prometheus (Metrics)
```bash
terraform output prometheus_url
```

### AlertManager (Alerts)
```bash
terraform output alertmanager_url
```

## Configuration

### Adding Scrape Targets

SSH to the instance and edit `/etc/prometheus/prometheus.yml`:

```yaml
scrape_configs:
  - job_name: 'my-app'
    static_configs:
      - targets: ['app-server:9100']
```

Then restart Prometheus:
```bash
sudo systemctl restart prometheus
```

### Creating Grafana Dashboards

1. Access Grafana UI
2. Go to Dashboards → Import
3. Use dashboard ID or upload JSON
4. Select Prometheus as datasource

Popular dashboards:
- Node Exporter Full: 1860
- Kubernetes Cluster: 7249

## Monitoring Installation

SSH into the instance:

```bash
# Get SSH command
terraform output ssh_command

# Check service status
sudo systemctl status prometheus
sudo systemctl status grafana-server
sudo systemctl status alertmanager
sudo systemctl status node_exporter

# View logs
sudo journalctl -u prometheus -f
sudo journalctl -u grafana-server -f
```

## Cost Optimization

- Default instance type is `t3.large` (~$0.08/hour, ~$58/month)
- Set `create_eip = false` to avoid Elastic IP charges (~$3.60/month)
- Remember to destroy when not in use: `terraform destroy`

## Integrating with Rancher

To monitor Rancher-managed clusters:

1. Install Prometheus ServiceMonitor in your clusters
2. Configure Prometheus federation in `/etc/prometheus/prometheus.yml`
3. Add cluster endpoints to scrape configs

## Troubleshooting

If services are not accessible:
1. Check instance is running: `aws ec2 describe-instances`
2. SSH to instance and check logs: `sudo journalctl -u prometheus`
3. Verify services are running: `sudo systemctl status prometheus grafana-server`
4. Check security group allows your IP address
5. Test locally: `curl http://localhost:9090/-/healthy`
