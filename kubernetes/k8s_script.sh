#!/bin/bash

# Exit on error and print each command for debugging purposes
set -xe

# Check if the required arguments are passed
# if [ "$#" -ne 4 ]; then
#   echo "Usage: $0 <deployment.yaml-path> <ECR-repository-name> <AWS-region> <image-tag>"
#   exit 1
# fi

# Assigning arguments to variables
#DEPLOYMENT_YAML_PATH=$1
ECR_REPOSITORY_NAME=$2
AWS_REGION=$3
IMAGE_TAG=$4

# AWS account ID retrieval (assumes AWS CLI is configured)
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# AWS ECR login
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

# Make changes to the deployment.yaml file
# The script looks for the 'image' field and replaces it with the new ECR image reference
sed -i "s|image:.*|image: ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPOSITORY_NAME}:${IMAGE_TAG}|g" "$DEPLOYMENT_YAML_PATH"

# Confirm the change
echo "Updated image reference in $DEPLOYMENT_YAML_PATH to: ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPOSITORY_NAME}:${IMAGE_TAG}"
