# Quick Start

This is simply the commands, with no explanation

```
mkdir -p ~/Developer/Projects; cd $_
# Archive existing demo directory, and create new
[ -d "suse-demo-aws" ] && { i=1; while [ -d "suse-demo-aws-$(date +%F)-$(printf '%02d' $i)" ]; do ((i++)); done; mv suse-demo-aws "suse-demo-aws-$(date +%F)-$(printf '%02d' $i)"; }
git clone https://github.com/jradtke-suse/suse-demo-aws.git; cd suse-demo-aws
# I have created a "hydrated" configuraiton and stored in a directory one-level higher
cp ../terraform.tfvars.example terraform.tfvars

# normally you would run the following
# cp ./terraform.tfvars.example terraform.tfvars
# vi terraform.tfvars

################################################
# The work begins here
################################################

for PROJECT in shared-services rancher-manager observability security
do
  # Create messaging explaining what we are doing
  cat << MYEOF 
# Deploying $PROJECT
  cd $PROJECT
  terraform init; terraform plan -var-file=../terraform.tfvars; echo "yes" | terraform apply -var-file=../terraform.tfvars
  cd -

MYEOF

# Then, do the things...
cd $PROJECT
terraform init; terraform plan -var-file=../terraform.tfvars; echo "yes" | terraform apply -var-file=../terraform.tfvars
cd - 

done

# Retrieve the output of each Project
for PROJECT in shared-services rancher-manager observability security
do
  cat << MYEOF
# Reviewing $PROJECT
  cd $PROJECT
  terraform output
  cd -

MYEOF

echo "######################################"
echo "# Output from: $PROJECT"
cd $PROJECT
terraform output
cd -
done

```
  
