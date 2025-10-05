# SUSE Demo Environment - AWS

This repository contains Terraform projects to deploy a complete SUSE product demo environment in AWS.


## Notes and Caveats 

* I have created a sub-domain for this demo (suse-demo-aws.kubernerdes.com) and an IAM principal with the appropriate permissions that allows me to create records in that domain. 
* Everything is in a public subnet (NATGW is not needed).
* While there is a separate directory for each SUSE product, they all rely on the tftstate file in the shared-services directory.  Therefore, do not modify the "shared-services" once it has been deployed, and remove that infrastructure last.

**NOTE:** This is ONLY intended to run as a demo/lab. Trade-offs have been made to minimize cost which make this approach unacceptable for production use-cases.


## Products Included

- **SUSE Rancher Manager** - Kubernetes management platform
- **SUSE Observability** - Monitoring and observability solution
- **SUSE Security** - Security and compliance tools

## Architecture

The demo environment is organized into separate Terraform projects:

- **shared-services/** - Common infrastructure (VPC, networking, security groups, etc.)
- **rancher-manager/** - SUSE Rancher Manager deployment
- **observability/** - SUSE Observability deployment
- **security/** - SUSE Security deployment

## Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform >= 1.5.0
- SSH key pair for EC2 instances

## Deployment Order

Deploy projects in the following order to ensure dependencies are met:

1. **Shared Services** - Deploy first to create common infrastructure
2. **SUSE Rancher Manager** - Deploy Rancher for Kubernetes management
3. **SUSE Observability** - Deploy monitoring stack
4. **SUSE Security** - Deploy security components

## Quick Start

### 1. Deploy Shared Services

```bash
cd shared-services
terraform init
terraform plan
terraform apply
```

### 2. Deploy SUSE Rancher Manager

```bash
cd ../rancher-manager
terraform init
terraform plan
terraform apply
```

### 3. Deploy SUSE Observability

```bash
cd ../observability
terraform init
terraform plan
terraform apply
```

### 4. Deploy SUSE Security

```bash
cd ../security
terraform init
terraform plan
terraform apply
```

## Configuration

Each project has its own `terraform.tfvars` file for customization. Review and update these files before deployment.

## Cleanup

To destroy all resources, run `terraform destroy` in reverse order:

Note: you will need to type "yes" and hit (enter) - I intentionally did not make this non-interactive
```bash
cd ./security && terraform destroy && cd -
cd ./observability && terraform destroy &&  cd -
cd ./rancher-manager && terraform destroy && cd -
cd ./shared-services && terraform destroy &&  cd -
```
