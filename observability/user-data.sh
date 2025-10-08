#!/bin/bash
set -e

# Log all output
exec > >(tee /var/log/user-data.log)
exec 2>&1

echo "Starting SLES 15 SUSE Observability (StackState) setup..."

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

# TODO: need to incorporate/add syntax to create TLS-SAN for the certs :-(
#       or... fix the certs post-install?

# Install K3s with specific options for single-node deployment
curl -sfL https://get.k3s.io | sh -s - server

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
# Configure Let's Encrypt ClusterIssuer (if enabled)
#######################################
%{ if enable_letsencrypt ~}
echo "Configuring Let's Encrypt ClusterIssuer..."

# Create ClusterIssuer for Let's Encrypt
cat <<'ISSUER_EOF' | kubectl apply -f -
${letsencrypt_clusterissuer}
ISSUER_EOF

echo "Let's Encrypt ClusterIssuers created (staging and production)"
echo "Using environment: ${letsencrypt_environment}"
%{ endif ~}

#######################################
# Install SUSE Observability
#######################################
echo "Installing SUSE Observability (StackState)..."

# I do this in a separate/well-known directory - not necessary
mkdir -p ~/Developer/Projects/observability.suse-demo-aws.kubernerdes.lab; cd $_

# Add the SUSE Observability Helm Repo
helm repo add suse-observability https://charts.rancher.com/server-charts/prime/suse-observability
helm repo update

# Create template files
export VALUES_DIR=.
helm template \
  --set license='${suse_observability_license}' \
  --set rancherUrl='${suse_rancher_url}' \
  --set baseUrl='${suse_observability_base_url}' \
  --set sizing.profile='10-nonha' \
  suse-observability-values \
  suse-observability/suse-observability-values --output-dir $VALUES_DIR

# Install using temmplate files created in previous step
helm upgrade --install \
    --namespace suse-observability \
    --create-namespace \
    --values $VALUES_DIR/suse-observability-values/templates/baseConfig_values.yaml \
    --values $VALUES_DIR/suse-observability-values/templates/sizing_values.yaml \
    --values $VALUES_DIR/suse-observability-values/templates/affinity_values.yaml \
    suse-observability \
    suse-observability/suse-observability

kubectl get all -n suse-observability

# Need to add check/wait here before proceeding

# temp port forward
kubectl port-forward service/suse-observability-router 8080:8080 --namespace suse-observability

# Expose App
cat << EOF | tee suse-observability-ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: suse-observability-ingress
  namespace: suse-observability
spec:
  rules:
    - host: ${hostname}.${subdomain}.${root_domain} 
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: suse-observability-router
                port:
                  number: 8080
EOF
kubectl apply -f suse-observability-ingress.yaml

#######################################
# Create Let's Encrypt Certificate (if enabled)
#######################################
%{ if enable_letsencrypt ~}
echo "Creating Let's Encrypt Certificate for SUSE Observability..."

# Now that suse-observability namespace exists, create the Certificate resource
cat <<'CERT_EOF' | kubectl apply -f -
${letsencrypt_certificate}
CERT_EOF

echo "Certificate resource created - cert-manager will request certificate from Let's Encrypt"
echo "Monitor certificate status with: kubectl describe certificate observability-tls -n suse-observability"
%{ endif ~}

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
echo "  Base URL: ${suse_observability_base_url}"
echo "  Username: admin"
echo "  $(grep 'admin password' $(find $HOME -name baseConfig_values.yaml))"
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
