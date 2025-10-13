# Post Install Steps

Once all the products have deployed and are avaiable (usually takes about 15 minutes for Observability to stabilze) then I recommend doing the following:

## High-level Steps
Add Rancher Manager Server to O11y
Add O11y to RMS

### Update Rancher Manager
Click on globe (lower left-hand side), which brings you to Settings
Scroll down and find "agent-tls-mode" and select "System Store"

### Add hosts to Observability
Login to both Rancher Manager Server and Observability Dashboard
click on local, then > Kubectl Shell (upper right)

Login to SUSE Observability (shoud default to the Stackpacks UI)
Enter "rancher" and click (???)
Click on CREATE NEW SERVICE TOKEN
Click on the bottom "COPY TO CLIPBOARD"

(go back to RMS Kubectl Shell)
paste the recently copied O11y bits
(go back to the O11y Dashboard)
cut-and-paste the bits from: Generic Kubernetes (including RKE2) - both sections 1. and 2.

You're done.  That's it.


### Add Clusters to Rancher Manager Server
Now go to RMS
Click on the Cluster Management (looks like a barn with a Silo on the left)
Click Import Existing (upper right)
Click Generic
Enter a Cluster Name (observability) and Description and click next.
(this will have generated commands to run - copy the top set of commands to your clipboard) 
SSH to O11y node
sudo to root and paste the commands
then run `kubectl get pods -n cattle-system -w`

# SSH to the neuvector node and repeat the RMS steps (and stay logged in)
Now, add a Stackpack for the neuvector cluster and paste the bits to the SSH terminal

You're done.  That's it.


### Add Clusters to SUSE Security (Neuvector) (not done)

#### Add new clusters
Click on Admin ^, then Multiple Clusters
Click Promote
