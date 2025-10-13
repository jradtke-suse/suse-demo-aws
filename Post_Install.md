# Post Install Steps

Once all the products have deployed and are avaiable (usually takes about 15 minutes for Observability to stabilze) then I recommend doing the following:

Add Rancher Manager Server to O11y
Add O11y to RMS

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

You're done.

Now go to RMS
Click on the Cluster Management (looks like a barn with a Silo on the left)
Click Import Existing (upper right)
Click Generic
Enter a Cluster Name (observability) and Description and click next.
(this will have generated commands to run - copy the middle set of commands to your clipboard) *
SSH to O11y node
sudo to root and paste the commands
then run `kubectl get pods -n cattle-system -w`

# SSH to the neuvector node and repeat the RMS steps (and stay logged in)
Now, add a Stackpack for the neuvector cluster and paste the bits to the SSH terminal


* I have found that using Let's Encrypt still results in CA errors (which I will resolve later).  So, use the insecure for now.  One nice side-effect from this not working is I have an issue service/pod to view in O11y ;-)

## Neuvector

### Add new clusters
Click on Admin ^, then Multiple Clusters
Click Promote
