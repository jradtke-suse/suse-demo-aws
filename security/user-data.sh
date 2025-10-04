#!/bin/bash
set -e

# Log all output
exec > >(tee /var/log/user-data.log)
exec 2>&1

echo "Starting SLES 15 Security setup..."

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

# Install required packages
zypper install -y curl wget

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Install Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Install K3s
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server --cluster-init" sh -

# Wait for K3s to be ready
until kubectl --kubeconfig /etc/rancher/k3s/k3s.yaml get nodes; do
  echo "Waiting for K3s to be ready..."
  sleep 5
done

# Set up kubeconfig
mkdir -p /root/.kube
cp /etc/rancher/k3s/k3s.yaml /root/.kube/config
chmod 600 /root/.kube/config

# Install NeuVector
kubectl create namespace neuvector || true

helm repo add neuvector https://neuvector.github.io/neuvector-helm/
helm repo update

# Create NeuVector values file
cat > /tmp/neuvector-values.yaml <<EOF
controller:
  replicas: 1

manager:
  enabled: true
  env:
    ssl: true
  svc:
    type: NodePort
    nodePort: 8443

cve:
  scanner:
    enabled: true
    replicas: 1

enforcer:
  enabled: true
EOF

helm install neuvector neuvector/core \
  --namespace neuvector \
  --values /tmp/neuvector-values.yaml \
  --version ${neuvector_version} \
  --wait

# Wait for NeuVector to be ready
kubectl wait --for=condition=ready pod -l app=neuvector-manager-pod -n neuvector --timeout=300s

# Install Trivy
wget https://github.com/aquasecurity/trivy/releases/download/v0.56.2/trivy_0.56.2_Linux-64bit.rpm
rpm -ivh trivy_0.56.2_Linux-64bit.rpm

# Create Trivy systemd service for server mode
cat > /etc/systemd/system/trivy-server.service <<EOF
[Unit]
Description=Trivy Server
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/trivy server --listen 0.0.0.0:8080
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

# Start Trivy server
systemctl daemon-reload
systemctl enable trivy-server
systemctl start trivy-server

# Install Falco (runtime security)
rpm --import https://falco.org/repo/falcosecurity-packages.asc
curl -s -o /etc/zypp/repos.d/falcosecurity.repo https://falco.org/repo/falcosecurity-rpm.repo
zypper refresh
zypper install -y falco

# Start Falco
systemctl enable falco
systemctl start falco

echo "SUSE Security stack installation complete!"
echo ""
echo "NeuVector UI: https://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):8443"
echo "  Default credentials: admin / admin"
echo ""
echo "Trivy Server: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):8080"
echo ""
echo "Falco runtime security is enabled and monitoring system calls"
echo ""
echo "To scan an image with Trivy:"
echo "  trivy image --server http://localhost:8080 your-image:tag"
