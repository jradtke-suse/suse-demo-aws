#!/bin/bash
set -e

# Log all output
exec > >(tee /var/log/user-data.log)
exec 2>&1

echo "Starting SLES 15 Kubernetes setup..."

#######################################
# SUSE Registration Configuration
#######################################
echo "Registering SLES 15 system with SUSE Customer Center..."

# Register the system with SUSE Customer Center
if [ -n "$SMT_URL" ]; then
    # Register with SMT/RMT server
    echo "SUSEConnect --url \"$SMT_URL\" --regcode \"$SUSE_REGCODE\" --email \"$SUSE_EMAIL\" "
    SUSEConnect --url "$SMT_URL" --regcode "$SUSE_REGCODE" --email "$SUSE_EMAIL"
else
    # Register with SUSE Customer Center (default)
    echo "SUSEConnect --regcode \"$SUSE_REGCODE\" --email \"$SUSE_EMAIL\" "
    SUSEConnect --regcode "$SUSE_REGCODE" --email "$SUSE_EMAIL"
fi

# Verify registration
SUSEConnect --status

echo "SLES registration completed successfully"

# Update system
zypper refresh
zypper update -y

# Install required packages
zypper install -y docker curl git

# Start and enable Docker
systemctl enable docker
systemctl start docker

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

# Install Rancher
helm repo add rancher-latest https://releases.rancher.com/server-charts/latest
helm repo update

kubectl create namespace cattle-system || true

helm install rancher rancher-latest/rancher \
  --namespace cattle-system \
  --set hostname=${hostname} \
  --set replicas=1 \
  --set bootstrapPassword=admin \
  --version ${rancher_version} \
  --wait

# Wait for Rancher to be ready
kubectl -n cattle-system rollout status deploy/rancher

echo "Rancher installation complete!"
echo "Access Rancher at: https://${hostname}"
echo "Bootstrap password: admin"
echo "Please change the password on first login"
