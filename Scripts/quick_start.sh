#!/bin/bash
#
# Quick Start Script for SUSE Demo AWS Infrastructure
#
# This script automates the deployment and teardown of the SUSE demo environment
# in AWS using Terraform modules.
#

set -e  # Exit on error

# Color codes for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Project deployment order (CRITICAL: shared-services must be first)
readonly PROJECTS=(shared-services rancher-manager observability security)

# Projects directory setup
readonly PROJECTS_DIR="${HOME}/Developer/Projects"
readonly REPO_URL="https://github.com/jradtke-suse/suse-demo-aws.git"
readonly REPO_NAME="suse-demo-aws"

#######################################
# Print colored message
# Arguments:
#   $1 - Color code
#   $2 - Message
#######################################
print_msg() {
    echo -e "${1}${2}${NC}"
}

#######################################
# Print section header
# Arguments:
#   $1 - Header text
#######################################
print_header() {
    echo
    print_msg "${BLUE}" "========================================"
    print_msg "${BLUE}" "$1"
    print_msg "${BLUE}" "========================================"
}

#######################################
# Archive existing demo directory with timestamp
# Globals:
#   PROJECTS_DIR, REPO_NAME
#######################################
archive_existing() {
    if [ -d "${PROJECTS_DIR}/${REPO_NAME}" ]; then
        local i=1
        local archive_name
        while true; do
            archive_name="${REPO_NAME}-$(date +%F)-$(printf '%02d' $i)"
            [ ! -d "${PROJECTS_DIR}/${archive_name}" ] && break
            ((i++))
        done
        print_msg "${YELLOW}" "Archiving existing directory to: ${archive_name}"
        mv "${PROJECTS_DIR}/${REPO_NAME}" "${PROJECTS_DIR}/${archive_name}"
    fi
}

#######################################
# Start: Deploy all infrastructure
#######################################
start() {
    print_header "Starting SUSE Demo AWS Deployment"

    # Create and navigate to projects directory
    mkdir -p "${PROJECTS_DIR}"
    cd "${PROJECTS_DIR}" || exit 1

    # Archive existing demo directory
    archive_existing

    # Clone repository
    print_msg "${GREEN}" "Cloning repository..."
    if ! git clone "${REPO_URL}"; then
        print_msg "${RED}" "Failed to clone repository"
        exit 1
    fi

    cd "${REPO_NAME}" || exit 1

    # Setup terraform.tfvars
    if [ -f "../terraform.tfvars.example" ]; then
        print_msg "${YELLOW}" "Using hydrated configuration from parent directory"
        cp ../terraform.tfvars.example terraform.tfvars
    elif [ -f "./terraform.tfvars.example" ]; then
        print_msg "${YELLOW}" "Copying terraform.tfvars.example - YOU MUST EDIT THIS FILE"
        cp ./terraform.tfvars.example terraform.tfvars
        print_msg "${RED}" "IMPORTANT: Edit terraform.tfvars with your configuration before proceeding"
        read -p "Press Enter to continue after editing terraform.tfvars..."
    else
        print_msg "${RED}" "ERROR: No terraform.tfvars.example found"
        exit 1
    fi

    # Deploy each project in order
    print_header "Deploying Infrastructure Modules"

    for PROJECT in "${PROJECTS[@]}"; do
        print_msg "${GREEN}" "Deploying: ${PROJECT}"

        cd "${PROJECT}" || exit 1

        terraform init || { print_msg "${RED}" "Failed to initialize ${PROJECT}"; exit 1; }
        terraform plan -var-file=../terraform.tfvars || { print_msg "${RED}" "Failed to plan ${PROJECT}"; exit 1; }
        echo "yes" | terraform apply -var-file=../terraform.tfvars || { print_msg "${RED}" "Failed to apply ${PROJECT}"; exit 1; }

        cd - > /dev/null || exit 1
        print_msg "${GREEN}" "Successfully deployed: ${PROJECT}"
    done

    # Display outputs
    print_header "Deployment Outputs"

    for PROJECT in "${PROJECTS[@]}"; do
        echo
        print_msg "${BLUE}" "Output from: ${PROJECT}"
        print_msg "${BLUE}" "----------------------------------------"
        cd "${PROJECT}" || exit 1
        terraform output
        cd - > /dev/null || exit 1
    done

    print_header "Deployment Complete!"
    print_msg "${GREEN}" "All infrastructure has been successfully deployed."
}

#######################################
# Stop: Destroy all infrastructure
# CRITICAL: Destroys in REVERSE order to respect dependencies
#######################################
stop() {
    print_header "Destroying SUSE Demo AWS Infrastructure"

    # Verify we're in the correct directory
    if [ ! -d "shared-services" ]; then
        print_msg "${RED}" "ERROR: Must be run from the suse-demo-aws repository root"
        print_msg "${YELLOW}" "Current directory: $(pwd)"
        exit 1
    fi

    # Confirm destruction
    print_msg "${RED}" "WARNING: This will destroy ALL infrastructure!"
    read -p "Are you sure you want to continue? (yes/no): " confirm
    if [ "${confirm}" != "yes" ]; then
        print_msg "${YELLOW}" "Destruction cancelled"
        exit 0
    fi

    # Destroy in REVERSE order (critical for state dependencies)
    local reversed_projects=($(printf '%s\n' "${PROJECTS[@]}" | tac))

    for PROJECT in "${reversed_projects[@]}"; do
        print_msg "${YELLOW}" "Destroying: ${PROJECT}"

        cd "${PROJECT}" || exit 1

        echo "yes" | terraform destroy -var-file=../terraform.tfvars || {
            print_msg "${RED}" "Failed to destroy ${PROJECT}"
            print_msg "${YELLOW}" "You may need to manually destroy remaining resources"
            exit 1
        }

        cd - > /dev/null || exit 1
        print_msg "${GREEN}" "Successfully destroyed: ${PROJECT}"
    done

    print_header "Destruction Complete!"
    print_msg "${GREEN}" "All infrastructure has been destroyed."
}

#######################################
# Display help information
#######################################
help() {
    cat << EOF

SUSE Demo AWS - Quick Start Script

USAGE:
    $(basename "$0") [OPTION]

OPTIONS:
    start       Deploy all SUSE demo infrastructure in AWS
                - Creates/archives project directory
                - Clones repository
                - Deploys: shared-services, rancher-manager, observability, security
                - Displays all outputs

    stop        Destroy all SUSE demo infrastructure
                - Destroys in reverse order: security, observability, rancher-manager, shared-services
                - Prompts for confirmation before proceeding
                - CRITICAL: Respects Terraform state dependencies

    help        Display this help message

DEPLOYMENT ORDER:
    The infrastructure MUST be deployed in this specific order due to state dependencies:
    1. shared-services (VPC, networking, security groups)
    2. rancher-manager (SUSE Rancher Manager)
    3. observability (SUSE Observability stack)
    4. security (SUSE Security tools)

DESTRUCTION ORDER:
    Infrastructure MUST be destroyed in REVERSE order:
    1. security
    2. observability
    3. rancher-manager
    4. shared-services

PREREQUISITES:
    - AWS CLI configured with valid credentials
    - Terraform >= 1.5.0 installed
    - SSH key pair generated
    - terraform.tfvars configured with your settings

EXAMPLES:
    # Deploy infrastructure
    $(basename "$0") start

    # Destroy infrastructure
    $(basename "$0") stop

    # Show help
    $(basename "$0") help

NOTES:
    - This is a DEMO/LAB environment only - not suitable for production
    - All modules share a single terraform.tfvars file
    - Default security settings allow access from 0.0.0.0/0
    - Restrict CIDR blocks in terraform.tfvars for production use

For more information, see: https://github.com/jradtke-suse/suse-demo-aws

EOF
}

#######################################
# Main execution
#######################################
main() {
    case "${1:-}" in
        start)
            start
            ;;
        stop)
            stop
            ;;
        help|--help|-h)
            help
            ;;
        "")
            print_msg "${RED}" "ERROR: No option specified"
            echo
            help
            exit 1
            ;;
        *)
            print_msg "${RED}" "ERROR: Invalid option: $1"
            echo
            help
            exit 1
            ;;
    esac
}

# Run main with all arguments
main "$@"
