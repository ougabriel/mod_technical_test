#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status

# Arguments
AWS_ACCOUNT_ID=$1
ECR_REPOSITORY=$2
TAG=${3:-latest}  # Default to "latest" if not provided
DEPLOYMENT_FILE=$4

# Fetch the latest image tag from ECR
LATEST_IMAGE=$(aws ecr describe-images --repository-name "$ECR_REPOSITORY" --query 'imageDetails[?contains(imageTags, `'"$TAG"'`)].imageTags[0]' --output text --region eu-west-2)

# Check if the LATEST_IMAGE is valid
if [ -z "$LATEST_IMAGE" ] || [ "$LATEST_IMAGE" == "None" ]; then
    echo "Error: Unable to find the latest image tag in the repository."
    exit 1
fi

# Replace the image in the deployment YAML file
sed -i "s|image: \".*\"|image: \"$AWS_ACCOUNT_ID.dkr.ecr.eu-west-2.amazonaws.com/$ECR_REPOSITORY:$LATEST_IMAGE\"|" "$DEPLOYMENT_FILE"

echo "Updated $DEPLOYMENT_FILE with image: $AWS_ACCOUNT_ID.dkr.ecr.eu-west-2.amazonaws.com/$ECR_REPOSITORY:$LATEST_IMAGE"
