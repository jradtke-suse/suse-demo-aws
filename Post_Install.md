# Post-Installation Integration Guide

After all products have deployed successfully (typically 15-20 minutes), follow these steps to integrate the SUSE products together for a complete demo environment.

## Prerequisites

- All three product modules deployed successfully:
  - Rancher Manager
  - SUSE Observability
  - SUSE Security (NeuVector)
- Access credentials for each product UI
- All services are accessible via their URLs

---

## Overview of Integration Steps

1. **Configure Rancher Manager TLS Settings** - Update certificate validation mode
2. **Add Rancher Manager to SUSE Observability** - Monitor the Rancher cluster
3. **Add Observability Cluster to Rancher Manager** - Manage from central location
4. **Add Security Cluster to Rancher Manager** - Centralized management
5. **Add Observability Cluster to SUSE Observability** - Monitor the observability platform itself
6. **Add Security Cluster to SUSE Observability** - Monitor the security platform

---

## 1. Configure Rancher Manager TLS Settings

First, update Rancher Manager to trust system certificates for agent communication.

### Steps:
1. Login to **Rancher Manager UI**
2. Click the **globe icon** in the lower left-hand corner
3. Navigate to **Settings**
4. Scroll down and find **"agent-tls-mode"**
5. Change the value to **"System Store"**
6. Click **Save**

**Why this matters:** This allows Rancher agents to properly validate TLS certificates when connecting to the Rancher server.

---

## 2. Add Rancher Manager to SUSE Observability

Integrate the Rancher Manager cluster with SUSE Observability for monitoring.

### Steps:

#### 2.1 Access Both UIs
1. Login to **SUSE Observability Dashboard** (should default to StackPacks UI)
2. In another tab, login to **Rancher Manager**
3. In Rancher, navigate to the **local** cluster
4. Click the **Kubectl Shell** button (upper right corner)

#### 2.2 Create Service Token in Observability
1. In the **SUSE Observability UI**, search for **"rancher"** in the StackPacks search
2. Select the **Rancher** StackPack
3. Click **CREATE NEW SERVICE TOKEN**
4. Click **COPY TO CLIPBOARD** at the bottom of the dialog

#### 2.3 Install Agent on Rancher Cluster
1. Go back to the **Rancher Kubectl Shell**
2. Paste the recently copied commands from Observability
3. Press Enter to execute

#### 2.4 Install Generic Kubernetes StackPack
1. Go back to **SUSE Observability UI**
2. Search for and select **"Generic Kubernetes (including RKE2)"** StackPack
3. Copy the commands from **Section 1** (Create Service Token) - paste into Kubectl Shell
4. Copy the commands from **Section 2** (Deploy Agent) - paste into Kubectl Shell
5. Execute both sets of commands

### Verify Integration:
```bash
# In Rancher Kubectl Shell, check agent deployment
kubectl get pods -n stackstate

# Wait for pods to be running
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=stackstate-agent -n stackstate --timeout=300s
```

**Result:** Rancher Manager cluster now appears in SUSE Observability dashboard with full topology and metrics.

---

## 3. Add Observability Cluster to Rancher Manager

Import the SUSE Observability cluster into Rancher for centralized management.

### Steps:

#### 3.1 Initiate Import in Rancher
1. In **Rancher Manager UI**, click **Cluster Management** (barn/silo icon on left)
2. Click **Import Existing** (upper right)
3. Select **Generic** as the cluster type
4. Enter cluster details:
   - **Cluster Name:** `observability`
   - **Description:** `SUSE Observability (StackState) Cluster`
5. Click **Create**

#### 3.2 Apply Registration to Observability Cluster
1. Rancher will display kubectl commands - **copy the first set** to clipboard
2. SSH to the **Observability node**:
   ```bash
   # From your local machine
   terraform output -raw ssh_command
   # Or manually:
   ssh -i ~/.ssh/suse-demo-aws.pem ec2-user@<observability-ip>
   ```
3. Switch to root:
   ```bash
   sudo su -
   ```
4. Paste and execute the Rancher registration commands
5. Monitor the agent deployment:
   ```bash
   kubectl get pods -n cattle-system -w
   ```

### Verify Integration:
Wait for all cattle-system pods to be Running, then check in Rancher UI:
- The observability cluster should appear in **Cluster Management**
- Cluster state should show as **Active**

---

## 4. Add Security Cluster to Rancher Manager

Import the SUSE Security (NeuVector) cluster into Rancher.

### Steps:

#### 4.1 Initiate Import in Rancher
1. In **Rancher Manager UI**, click **Cluster Management**
2. Click **Import Existing** (upper right)
3. Select **Generic**
4. Enter cluster details:
   - **Cluster Name:** `security`
   - **Description:** `SUSE Security (NeuVector) Cluster`
5. Click **Create**

#### 4.2 Apply Registration to Security Cluster
1. Copy the first set of kubectl commands from Rancher
2. SSH to the **Security node**:
   ```bash
   ssh -i ~/.ssh/suse-demo-aws.pem ec2-user@<security-ip>
   ```
3. Switch to root:
   ```bash
   sudo su -
   ```
4. Paste and execute the Rancher registration commands
5. Monitor the deployment:
   ```bash
   kubectl get pods -n cattle-system -w
   ```

### Verify Integration:
- Security cluster appears in Rancher **Cluster Management**
- Cluster state shows as **Active**

**Stay logged in to the security node** - you'll need it for the next step.

---

## 5. Add Observability Cluster to SUSE Observability

Configure SUSE Observability to monitor its own cluster.

### Steps:

#### 5.1 Get StackPack Installation Commands
1. In **SUSE Observability UI**, search for **"Generic Kubernetes"**
2. Select the **Generic Kubernetes (including RKE2)** StackPack
3. Click **Add new instance** or **Create Service Token**
4. Copy the commands for both sections (token creation and agent deployment)

#### 5.2 Deploy Agent to Observability Cluster
1. SSH to the **Observability node** (if not already connected)
2. Switch to root: `sudo su -`
3. Paste and execute the token creation commands
4. Paste and execute the agent deployment commands
5. Verify deployment:
   ```bash
   kubectl get pods -n stackstate
   kubectl logs -n stackstate -l app.kubernetes.io/name=stackstate-agent --tail=50
   ```

### Verify Integration:
- Observability cluster appears in SUSE Observability dashboard
- Full topology and metrics are visible

---

## 6. Add Security Cluster to SUSE Observability

Configure SUSE Observability to monitor the security cluster.

### Steps:

#### 6.1 Get StackPack Installation Commands
1. In **SUSE Observability UI**, create another instance of **Generic Kubernetes** StackPack
2. Copy the installation commands (same as step 5)

#### 6.2 Deploy Agent to Security Cluster
1. Use the SSH session to the **Security node** (should still be logged in from step 4)
2. Ensure you're root: `sudo su -`
3. Paste and execute the token creation commands
4. Paste and execute the agent deployment commands
5. Verify deployment:
   ```bash
   kubectl get pods -n stackstate
   kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=stackstate-agent -n stackstate --timeout=300s
   ```

### Verify Integration:
- Security cluster appears in SUSE Observability dashboard
- NeuVector components are visible in topology view

---

## 7. Configure NeuVector Multi-Cluster (Optional)

If you want centralized security policy management across all clusters:

### Steps:
1. Login to **NeuVector UI** on the security cluster
2. Click on **Admin** dropdown (upper right)
3. Navigate to **Multiple Clusters**
4. Click **Promote** to promote this cluster to Primary
5. Follow the UI wizard to generate federation tokens
6. Apply federation tokens to other clusters (Rancher and Observability)

**Note:** This step is optional and for advanced multi-cluster security management.

---

## Post-Integration Validation

After completing all integrations, verify the setup:

### Rancher Manager
- [ ] All three clusters visible in Cluster Management
- [ ] All clusters show Active state
- [ ] Can kubectl into each cluster from Rancher UI
- [ ] Agent TLS mode set to "System Store"

### SUSE Observability
- [ ] All three clusters visible in topology
- [ ] Metrics flowing from all clusters
- [ ] Health status showing for all components
- [ ] No critical alerts for cluster connectivity

### SUSE Security (NeuVector)
- [ ] NeuVector UI accessible
- [ ] Container scanning working
- [ ] Network policies visible
- [ ] Runtime protection enabled

---

## Troubleshooting

### Agent Pods Not Starting
```bash
# Check pod status
kubectl get pods -n cattle-system
kubectl get pods -n stackstate

# View logs
kubectl logs -n cattle-system -l app=cattle-cluster-agent
kubectl logs -n stackstate -l app.kubernetes.io/name=stackstate-agent
```

### Cluster Not Appearing in Rancher
- Verify cattle-system namespace exists: `kubectl get ns`
- Check registration URL is accessible from the cluster
- Ensure security groups allow required ports

### SUSE Observability Agent Not Connecting
- Verify Observability Router is accessible (port 8080)
- Check service token is valid
- Review agent logs for connection errors

### General Connectivity Issues
- Verify all EIPs are associated
- Check Route53 DNS records are resolving
- Confirm security groups allow required ports
- Test network connectivity: `curl -v https://<service-url>`

---

## Next Steps

After integration is complete:

1. **Explore SUSE Observability**
   - Review topology maps
   - Set up custom dashboards
   - Configure alerting rules

2. **Configure NeuVector Policies**
   - Enable runtime protection
   - Set up network segmentation
   - Configure compliance scanning

3. **Deploy Test Applications**
   - Deploy sample apps to Rancher clusters
   - Monitor via SUSE Observability
   - Apply security policies via NeuVector

4. **Set Up Continuous Monitoring**
   - Configure alert notifications
   - Set up log aggregation
   - Enable automated response actions

---

## Summary

You have successfully integrated:
- ✅ Rancher Manager with SUSE Observability monitoring
- ✅ Three Kubernetes clusters under Rancher management
- ✅ Complete observability across all clusters
- ✅ Centralized security monitoring and policy enforcement

Your SUSE demo environment is now fully operational!
