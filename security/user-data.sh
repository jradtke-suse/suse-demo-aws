#!/bin/bash
set -e

# Log all output
exec > >(tee /var/log/user-data.log)
exec 2>&1

echo "Starting SLES 15 Security setup..."
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

# Wait for K3s service to be active
echo "Waiting for K3s service to be active..."
until systemctl is-active --quiet k3s; do
  echo "K3s service not yet active..."
  sleep 5
done

# Set up kubeconfig and bash ENV for root/ec2-user
mkdir -p /root/.kube
cp /etc/rancher/k3s/k3s.yaml /root/.kube/config
chmod 600 /root/.kube/config
export KUBECONFIG=/root/.kube/config
cat << EOF | tee -a /root/.bashrc
export KUBECONFIG=/root/.kube/config
alias kge='clear; kubectl get events --sort-by=.lastTimestamp'
alias kgea='clear; kubectl get events -A --sort-by=.lastTimestamp'
set -o vi
EOF
cat << EOF | tee -a /home/ec2-user/.bashrc
export KUBECONFIG=~/.kube/config
alias kge='clear; kubectl get events --sort-by=.lastTimestamp'
alias kgea='clear; kubectl get events -A --sort-by=.lastTimestamp'
set -o vi
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

#######################################
# Install cert-manager
#######################################
echo "Installing cert-manager..."

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
# Install NeuVector
#######################################
echo "Installing NeuVector..."

kubectl create namespace neuvector || true

helm repo add neuvector https://neuvector.github.io/neuvector-helm/
helm repo update

# Create NeuVector values file
cat > /tmp/neuvector-values.yaml <<NVEOF
controller:
  replicas: 1

manager:
  enabled: true
  env:
    ssl: false
  svc:
    type: ClusterIP

cve:
  scanner:
    enabled: true
    replicas: 1

enforcer:
  enabled: true
NVEOF

helm install neuvector neuvector/core \
  --namespace neuvector \
  --values /tmp/neuvector-values.yaml \
  --wait

# Wait for NeuVector to be ready
echo "Waiting for NeuVector deployment to be available..."
kubectl wait --for=condition=available --timeout=600s deployment/neuvector-controller-pod -n neuvector || true
kubectl wait --for=condition=available --timeout=600s deployment/neuvector-manager-pod -n neuvector || true

# Wait for NeuVector pods to be fully running
echo "Waiting for NeuVector pods to be ready..."
kubectl wait --for=condition=ready --timeout=600s pod -l app=neuvector-manager-pod -n neuvector || true

#######################################
# Create Ingress for NeuVector
#######################################
echo "Creating Ingress for NeuVector..."

cat > /tmp/neuvector-ingress.yaml <<INGEOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: neuvector-ingress
  namespace: neuvector
  annotations:
    nginx.ingress.kubernetes.io/backend-protocol: "HTTPS"
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
spec:
%{ if enable_letsencrypt ~}
  tls:
    - hosts:
        - ${hostname}
      secretName: tls-security-ingress
%{ endif ~}
  rules:
    - host: ${hostname}
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: neuvector-service-webui
                port:
                  number: 8443
INGEOF

kubectl apply -f /tmp/neuvector-ingress.yaml

#######################################
# Create Let's Encrypt Certificate (if enabled)
#######################################
%{ if enable_letsencrypt ~}
echo "Creating Let's Encrypt Certificate for NeuVector..."

# Now that neuvector namespace exists, create the Certificate resource
cat <<'CERT_EOF' | kubectl apply -f -
${letsencrypt_certificate}
CERT_EOF

echo "Certificate resource created - cert-manager will request certificate from Let's Encrypt"
echo "Monitor certificate status with: kubectl describe certificate security-tls -n neuvector"
%{ endif ~}

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

#######################################
# Final Status
#######################################
echo "SUSE Security stack installation complete!"
echo "=========================================="
echo ""
echo "NeuVector Access:"
%{ if enable_letsencrypt ~}
echo "  URL: https://${hostname}"
%{ else ~}
echo "  URL: https://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)"
%{ endif ~}
echo "  Default credentials: admin / admin"
echo "  IMPORTANT: Change password on first login!"
echo ""
echo "Trivy Server: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):8080"
echo ""
echo "Falco runtime security is enabled and monitoring system calls"
echo ""
echo "To check deployment status:"
echo "  kubectl get pods -n neuvector"
echo "  kubectl get ingress -n neuvector"
%{ if enable_letsencrypt ~}
echo "  kubectl get certificate -n neuvector"
%{ endif ~}
echo ""
echo "To scan an image with Trivy:"
echo "  trivy image --server http://localhost:8080 your-image:tag"
echo ""
echo "Installation logs: /var/log/user-data.log"
