# #!/bin/bash

# # Exit immediately if a command exits with a non-zero status.
# set -e

# # Function to display usage information
# usage() {
#     echo "Usage: $0 <aws-region> <ecr-repository> <image-tag> <deployment-file>"
#     echo
#     echo "Arguments:"
#     echo "  aws-region       : AWS region where the ECR repository is located"
#     echo "  ecr-repository   : Name of the ECR repository"
#     echo "  image-tag        : Tag of the Docker image to use"
#     echo "  deployment-file  : Path to the Kubernetes deployment.yaml file"
# }

# # Check if the correct number of arguments is provided
# if [ "$#" -ne 4 ]; then
#     echo "Error: Incorrect number of arguments"
#     usage
#     exit 1
# fi

# # Assign arguments to variables
# AWS_REGION="$1"
# ECR_REPOSITORY="$2"
# IMAGE_TAG="$3"
# DEPLOYMENT_FILE="$4"

# echo "Received arguments:"
# echo "AWS_REGION: $AWS_REGION"
# echo "ECR_REPOSITORY: $ECR_REPOSITORY"
# echo "IMAGE_TAG: $IMAGE_TAG"
# echo "DEPLOYMENT_FILE: $DEPLOYMENT_FILE"

# # Get AWS account ID
# AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# echo "Logging in to Amazon ECR..."
# aws ecr get-login-password --region "$AWS_REGION" | docker login --username AWS --password-stdin "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"

# # Construct the full image URL
# FULL_IMAGE_URL="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPOSITORY:$IMAGE_TAG"

# echo "Updating Kubernetes deployment file..."
# # Use sed to replace the image in the deployment file
# # This assumes that the image is specified in the format "image: <image-url>"
# sed -i "s|image: .*|image: $FULL_IMAGE_URL|" "$DEPLOYMENT_FILE"

# echo "Deployment file updated successfully."
# echo "New image: $FULL_IMAGE_URL"

# # Optionally, output the updated deployment file content
# echo "Updated deployment file content:"
# cat "$DEPLOYMENT_FILE"

# echo "Script execution completed."

#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# Function to display usage information
usage() {
    echo "Usage: $0 <aws-region> <ecr-repository> <kubernetes-yaml>"
    echo
    echo "Arguments:"
    echo "  aws-region       : AWS region where the ECR repository is located"
    echo "  ecr-repository   : Name of the ECR repository"
    echo "  kubernetes-yaml  : Path to the Kubernetes YAML file to update"
}

# Check if the correct number of arguments is provided
if [ "$#" -ne 3 ]; then
    echo "Error: Incorrect number of arguments"
    usage
    exit 1
fi

# Assign arguments to variables
AWS_REGION="$1"
ECR_REPOSITORY="$2"
K8S_YAML="$3"

echo "Received arguments:"
echo "AWS_REGION: $AWS_REGION"
echo "ECR_REPOSITORY: $ECR_REPOSITORY"
echo "K8S_YAML: $K8S_YAML"

# Get AWS account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

echo "Logging in to Amazon ECR..."
aws ecr get-login-password --region "$AWS_REGION" | docker login --username AWS --password-stdin "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"

# Get the latest image details
LATEST_IMAGE=$(aws ecr describe-images --repository-name "$ECR_REPOSITORY" --region "$AWS_REGION" --query 'sort_by(imageDetails,& imagePushedAt)[-1]')
IMAGE_TAG=$(echo "$LATEST_IMAGE" | jq -r '.imageTags[0]')

if [ -z "$IMAGE_TAG" ]; then
    echo "Error: No images found in the repository"
    exit 1
fi

# Construct the full image URL
FULL_IMAGE_URL="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPOSITORY:$IMAGE_TAG"

echo "Latest image: $FULL_IMAGE_URL"

echo "Updating Kubernetes YAML file..."
# Use sed to replace the image in the YAML file
# This assumes that the image is specified in the format "image: <image-url>"
sed -i "s|image: .*|image: $FULL_IMAGE_URL|" "$K8S_YAML"

echo "Kubernetes YAML file updated successfully."
echo "New image: $FULL_IMAGE_URL"

# Optionally, output the updated YAML file content
echo "Updated Kubernetes YAML file content:"
cat "$K8S_YAML"

echo "Script execution completed."