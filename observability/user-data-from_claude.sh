#!/bin/bash
set -e

# Log all output
exec > >(tee /var/log/user-data.log)
exec 2>&1

echo "Starting SLES 15 SUSE Observability (StackState) setup..."

#######################################
# SUSE Registration
#######################################
echo "Registering SLES 15 system with SUSE Customer Center..."

# Register the system with SUSE Customer Center
if [ -n "${smt_url}" ]; then
    # Register with SMT/RMT server
    echo "SUSEConnect --url \"${smt_url}\" --regcode \"${suse_regcode}\" --email \"${suse_email}\" "
    SUSEConnect --url "${smt_url}" --regcode "${suse_regcode}" --email "${suse_email}"
else
    # Register with SUSE Customer Center (default)
    echo "SUSEConnect --regcode \"${suse_regcode}\" --email \"${suse_email}\" "
    SUSEConnect --regcode "${suse_regcode}" --email "${suse_email}"
fi

# Verify registration
SUSEConnect --status

echo "SLES registration completed successfully"

# Update system
zypper refresh
zypper update -y

#######################################
# Install Required Packages
#######################################
echo "Installing required packages..."
zypper install -y curl wget git-core apparmor-parser

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Install Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Verify Helm installation
helm version

#######################################
# Install K3s (Lightweight Kubernetes)
#######################################
echo "Installing K3s..."

# Install K3s with specific options for single-node deployment
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server \ 
  --cluster-init \
  --disable traefik \
  --write-kubeconfig-mode 644" sh -

# Wait for K3s service to be active
echo "Waiting for K3s service to be active..."
until systemctl is-active --quiet k3s; do
  echo "K3s service not yet active..."
  sleep 5
done

# Set up kubeconfig
mkdir -p /root/.kube
cp /etc/rancher/k3s/k3s.yaml /root/.kube/config
chmod 600 /root/.kube/config
export KUBECONFIG=/root/.kube/config
echo "export KUBECONFIG=/root/.kube/config" >> /root/.bashrc

# Verify K3s installation
# Wait for K3s API server to be responsive
echo "Waiting for K3s API server to be ready..."
until kubectl get nodes > /dev/null 2>&1; do
  echo "K3s API server not yet responsive..."
  sleep 5
done

# Wait for K3s API server to be responsive
echo "Waiting for K3s API server to be ready..."
until kubectl get nodes > /dev/null 2>&1; do
  echo "K3s API server not yet responsive..."
  sleep 5
done

# Wait for nodes to be Ready
echo "Waiting for K3s node to be Ready..."
until kubectl wait --for=condition=Ready nodes --all --timeout=10s > /dev/null 2>&1; do
  echo "K3s node not yet ready..."
  sleep 5
done

# Wait for core K3s components to be running
echo "Waiting for core K3s components..."
until kubectl get deployment -n kube-system coredns > /dev/null 2>&1; do
  echo "CoreDNS not yet deployed..."
  sleep 5
done

kubectl wait --for=condition=available --timeout=300s deployment/coredns -n kube-system

echo "K3s is fully ready!"

# Install cert-manager
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v${cert_manager_version}/cert-manager.crds.yaml

helm repo add jetstack https://charts.jetstack.io
helm repo update

kubectl create namespace cert-manager || true

helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --version v${cert_manager_version} \
  --wait

# Wait for cert-manager to be ready
kubectl wait --for=condition=ready pod -l app.kubernetes.io/instance=cert-manager -n cert-manager --timeout=300s

#######################################
# Install SUSE Observability
#######################################
echo "Installing SUSE Observability (StackState)..."

# Add SUSE Observability Helm repository
helm repo add suse-observability https://charts.rancher.com/server-charts/prime/suse-observability
helm repo update

# Create namespace for SUSE Observability
kubectl create namespace suse-observability

# Generate SUSE Observability configuration files
export VALUES_DIR=/opt/suse-observability
mkdir -p $VALUES_DIR

echo "Generating SUSE Observability configuration..."
helm template \
  --set license='${suse_observability_license}' \
  --set baseUrl='${suse_observability_base_url}' \
  --set sizing.profile='10-nonha' \
  suse-observability-values \
  suse-observability/suse-observability-values --output-dir $VALUES_DIR

# Configure storage class for K3s (uses local-path provisioner)
cat > $VALUES_DIR/storage-override.yaml <<EOF
global:
  storageClass: "local-path"
EOF

# Set admin password if provided
if [ -n "${suse_observability_admin_password}" ]; then
  cat > $VALUES_DIR/auth-override.yaml <<EOF
stackstate:
  components:
    api:
      auth:
        adminPassword: "${suse_observability_admin_password}"
EOF
  EXTRA_VALUES="--values $VALUES_DIR/auth-override.yaml"
else
  EXTRA_VALUES=""
fi

# Install SUSE Observability with Helm
echo "Deploying SUSE Observability..."
helm upgrade \
  --install \
  --namespace suse-observability \
  --values $VALUES_DIR/suse-observability-values/templates/baseConfig_values.yaml \
  --values $VALUES_DIR/suse-observability-values/templates/sizing_values.yaml \
  --values $VALUES_DIR/suse-observability-values/templates/affinity_values.yaml \
  --values $VALUES_DIR/storage-override.yaml \
  $EXTRA_VALUES \
  --timeout 30m \
  --wait \
  suse-observability \
  suse-observability/suse-observability

#######################################
# Configure Access
#######################################
echo "Configuring SUSE Observability access..."

# Get the admin password
ADMIN_PASSWORD=$(kubectl get secret \
  --namespace suse-observability \
  suse-observability-admin-credentials \
  -o jsonpath='{.data.password}' 2>/dev/null | base64 -d || echo "Password not yet generated")

# Save credentials to file
cat > /root/suse-observability-credentials.txt <<EOF
SUSE Observability Credentials
==============================
URL: ${suse_observability_base_url}
Username: admin
Password: $ADMIN_PASSWORD

To access the UI via port-forward:
kubectl port-forward --address 0.0.0.0 service/suse-observability-suse-observability-router 8080:8080 --namespace suse-observability

Then access: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):8080
EOF

# Create systemd service for port-forwarding (optional, for external access without ingress)
cat > /etc/systemd/system/suse-observability-port-forward.service <<EOF
[Unit]
Description=SUSE Observability Port Forward
After=k3s.service
Requires=k3s.service

[Service]
Type=simple
Restart=always
RestartSec=10
ExecStart=/usr/local/bin/k3s kubectl port-forward --address 0.0.0.0 service/suse-observability-suse-observability-router 8080:8080 --namespace suse-observability
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# Enable and start port-forward service
systemctl daemon-reload
systemctl enable suse-observability-port-forward.service
systemctl start suse-observability-port-forward.service

#######################################
# Final Status
#######################################
echo "SUSE Observability installation complete!"
echo "=========================================="
echo ""
echo "SUSE Observability is deployed on Kubernetes (K3s)"
echo "Sizing Profile: 10-nonha (non-HA, up to 10 nodes)"
echo ""
echo "Access Information:"
echo "  URL: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):8080"
echo "  Base URL: ${suse_observability_base_url}"
echo "  Username: admin"
echo "  Password: See /root/suse-observability-credentials.txt"
echo ""
echo "Kubernetes (K3s) Access:"
echo "  KUBECONFIG: /etc/rancher/k3s/k3s.yaml"
echo "  kubectl get pods -n suse-observability"
echo ""
echo "To check deployment status:"
echo "  kubectl get pods -n suse-observability"
echo "  kubectl get svc -n suse-observability"
echo ""
echo "Credentials saved to: /root/suse-observability-credentials.txt"
echo "Installation logs: /var/log/user-data.log"
