#!/bin/bash
set -e

# Update system
zypper refresh
zypper update -y

# Install required packages
zypper install -y docker curl wget git

# Start and enable Docker
systemctl enable docker
systemctl start docker

# Create directories for observability stack
mkdir -p /opt/observability/{prometheus,grafana,alertmanager}
mkdir -p /etc/prometheus
mkdir -p /etc/alertmanager

# Install Prometheus
cd /tmp
PROM_VERSION="2.54.1"
wget https://github.com/prometheus/prometheus/releases/download/v$${PROM_VERSION}/prometheus-$${PROM_VERSION}.linux-amd64.tar.gz
tar xvfz prometheus-$${PROM_VERSION}.linux-amd64.tar.gz
cd prometheus-$${PROM_VERSION}.linux-amd64
cp prometheus promtool /usr/local/bin/
cp -r consoles console_libraries /etc/prometheus/

# Create Prometheus configuration
cat > /etc/prometheus/prometheus.yml <<EOF
global:
  scrape_interval: 15s
  evaluation_interval: 15s

alerting:
  alertmanagers:
    - static_configs:
        - targets:
            - localhost:9093

rule_files:
  # - "alerts.yml"

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'node_exporter'
    static_configs:
      - targets: ['localhost:9100']

  - job_name: 'alertmanager'
    static_configs:
      - targets: ['localhost:9093']
EOF

# Create Prometheus systemd service
cat > /etc/systemd/system/prometheus.service <<EOF
[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target

[Service]
User=root
Group=root
Type=simple
ExecStart=/usr/local/bin/prometheus \
  --config.file=/etc/prometheus/prometheus.yml \
  --storage.tsdb.path=/opt/observability/prometheus \
  --web.console.templates=/etc/prometheus/consoles \
  --web.console.libraries=/etc/prometheus/console_libraries

[Install]
WantedBy=multi-user.target
EOF

# Install Node Exporter
cd /tmp
NODE_EXPORTER_VERSION="1.8.2"
wget https://github.com/prometheus/node_exporter/releases/download/v$${NODE_EXPORTER_VERSION}/node_exporter-$${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz
tar xvfz node_exporter-$${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz
cp node_exporter-$${NODE_EXPORTER_VERSION}.linux-amd64/node_exporter /usr/local/bin/

# Create Node Exporter systemd service
cat > /etc/systemd/system/node_exporter.service <<EOF
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=root
Group=root
Type=simple
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=multi-user.target
EOF

# Install AlertManager
cd /tmp
ALERTMANAGER_VERSION="0.27.0"
wget https://github.com/prometheus/alertmanager/releases/download/v$${ALERTMANAGER_VERSION}/alertmanager-$${ALERTMANAGER_VERSION}.linux-amd64.tar.gz
tar xvfz alertmanager-$${ALERTMANAGER_VERSION}.linux-amd64.tar.gz
cp alertmanager-$${ALERTMANAGER_VERSION}.linux-amd64/alertmanager /usr/local/bin/
cp alertmanager-$${ALERTMANAGER_VERSION}.linux-amd64/amtool /usr/local/bin/

# Create AlertManager configuration
cat > /etc/alertmanager/alertmanager.yml <<EOF
global:
  resolve_timeout: 5m

route:
  group_by: ['alertname']
  group_wait: 10s
  group_interval: 10s
  repeat_interval: 1h
  receiver: 'default'

receivers:
  - name: 'default'
    # Configure your notification channels here

inhibit_rules:
  - source_match:
      severity: 'critical'
    target_match:
      severity: 'warning'
    equal: ['alertname', 'dev', 'instance']
EOF

# Create AlertManager systemd service
cat > /etc/systemd/system/alertmanager.service <<EOF
[Unit]
Description=AlertManager
Wants=network-online.target
After=network-online.target

[Service]
User=root
Group=root
Type=simple
ExecStart=/usr/local/bin/alertmanager \
  --config.file=/etc/alertmanager/alertmanager.yml \
  --storage.path=/opt/observability/alertmanager

[Install]
WantedBy=multi-user.target
EOF

# Start Prometheus stack
systemctl daemon-reload
systemctl enable prometheus node_exporter alertmanager
systemctl start prometheus node_exporter alertmanager

# Install Grafana
zypper addrepo https://rpm.grafana.com/oss/rpm grafana
rpm --import https://rpm.grafana.com/gpg.key
zypper refresh
zypper install -y grafana

# Configure Grafana
cat > /etc/grafana/grafana.ini <<EOF
[server]
http_port = 3000

[security]
admin_user = admin
admin_password = ${grafana_admin_password}

[auth.anonymous]
enabled = false
EOF

# Start Grafana
systemctl enable grafana-server
systemctl start grafana-server

# Wait for Grafana to start
sleep 10

# Add Prometheus as datasource to Grafana
curl -X POST http://admin:${grafana_admin_password}@localhost:3000/api/datasources \
  -H "Content-Type: application/json" \
  -d '{
    "name":"Prometheus",
    "type":"prometheus",
    "url":"http://localhost:9090",
    "access":"proxy",
    "isDefault":true
  }'

echo "SUSE Observability stack installation complete!"
echo "Grafana: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):3000"
echo "Prometheus: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):9090"
echo "AlertManager: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):9093"
echo "Grafana credentials: admin / ${grafana_admin_password}"
