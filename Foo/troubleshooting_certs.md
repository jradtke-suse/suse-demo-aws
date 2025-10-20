# Troubleshooting Certs

I use the following to troubleshoot any certificate issues (which are primarily due to exceeding rate limit).  
I tried using "staging" with Let's Encrypt, but would get browser errors and connectivity issues between clusters and services due to untrusted CA.

# Update the following var(s):
DAENV=staging # staging production are the 2 options

# Gather some infor re: Name of cert and Namespace
# NOTE: this, obviously, would not work on a system with a bunch of certificates.  This command is only for this demo 
DANAMESPACE=$(kubectl get certificate -A --no-headers -o custom-columns=NAME:metadata.namespace)
DACERTNAME=$(kubectl get certificate -A --no-headers -o custom-columns=NAME:metadata.name)

# First, let's review the status - if this says True in column 3, it was successful
kubectl get certificate -A --no-headers
kubectl describe certificate $DACERTNAME -n $DANAMESPACE

# Then we will check request and status
kubectl get certificaterequest -n $DANAMESPACE 
kubectl describe certificaterequest $DACERTNAME -n $DANAMESPACE

kubectl describe clusterissuer letsencrypt-$DAENV

# Check the logs of cert-manager
kubect logs -l app=cert-manager -n cert-manager



