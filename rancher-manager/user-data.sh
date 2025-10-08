#!/bin/bash
set -e

# Log all output
exec > >(tee /var/log/user-data.log)
exec 2>&1

echo "Starting SLES 15 Kubernetes setup..."
echo "Running as: $(whoami)"
echo "Started at: $(date)"

#######################################
# SUSE Registration and update
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
# Install required packages
#######################################
zypper install -y curl wget git-core

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Install Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

#######################################
# Install K3s
#######################################
curl -sfL https://get.k3s.io | sh -s - server
# curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server --cluster-init" sh -

# Wait for K3s service to be active
echo "Waiting for K3s service to be active..."
until systemctl is-active --quiet k3s; do
  echo "K3s service not yet active..."
  sleep 5
done

# Set up kubeconfig and bash ENV for root
mkdir -p /root/.kube
cp /etc/rancher/k3s/k3s.yaml /root/.kube/config
chmod 600 /root/.kube/config
export KUBECONFIG=/root/.kube/config
echo << EOF | tee -a /root/.bashrc
export KUBECONFIG=/root/.kube/config
alias kge='clear; kubectl get events --sort-by=.lastTimestamp'
alias kgea='clear; kubectl get events -A --sort-by=.lastTimestamp'
EOF

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

# Install Rancher
helm repo add rancher-stable https://releases.rancher.com/server-charts/stable
helm repo update

kubectl create namespace cattle-system || true

helm install rancher rancher-stable/rancher \
  --namespace cattle-system \
  --set hostname=${hostname} \
  --set replicas=1 \
  --set bootstrapPassword=admin \
  --version ${rancher_version} \
  --wait \
  --timeout 15m

# Wait for Rancher to be ready
echo "Waiting for Rancher deployment to be available..."
kubectl -n cattle-system wait --for=condition=available --timeout=600s deployment/rancher

# Wait for Rancher pods to be fully running
echo "Waiting for Rancher pods to be ready..."
kubectl -n cattle-system wait --for=condition=ready --timeout=600s pod -l app=rancher

echo "Rancher installation complete!"
echo "Access Rancher at: https://${hostname}"
echo "Bootstrap password: admin"
echo "Please change the password on first login"
