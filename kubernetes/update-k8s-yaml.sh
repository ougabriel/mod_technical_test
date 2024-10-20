#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status

# Constants
DEPLOYMENT_FILE="./kubernetes/deployment.yaml"
ECR_IMAGE="019485243761.dkr.ecr.eu-west-2.amazonaws.com/gabapprepodev:latest"

# Check if the deployment file exists
if [[ ! -f "$DEPLOYMENT_FILE" ]]; then
    echo "Error: Deployment file $DEPLOYMENT_FILE does not exist."
    exit 1
fi

# Update the image in the deployment YAML file
sed -i.bak "s|image: \".*\"|image: \"$ECR_IMAGE\"|" "$DEPLOYMENT_FILE"

# Inform the user of the update
echo "Updated $DEPLOYMENT_FILE with image: $ECR_IMAGE"
