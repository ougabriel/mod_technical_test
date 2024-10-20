# #!/bin/bash

# # Variables
# DEPLOYMENT_YAML_PATH="./kubernetes/deployment.yaml"
# AWS_REGION="eu-west-2"
# REPOSITORY_NAME="gabapprepodev"
# IMAGE_TAG="latest"  # Assuming you want to use the 'latest' tag

# # Retrieve the AWS Account ID and the latest image tag
# AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
# LATEST_IMAGE_TAG=$(aws ecr describe-images --repository-name "$REPOSITORY_NAME" --region "$AWS_REGION" \
#   --query 'imageDetails[?contains(imageTags, `'"$IMAGE_TAG"'`)].imageTags[0]' --output text)

# if [ -z "$LATEST_IMAGE_TAG" ]; then
#   echo "Error: Unable to find the latest image tag in the repository."
#   exit 1
# fi

# # Formulate the full image URI
# ECR_IMAGE_URI="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$REPOSITORY_NAME:$LATEST_IMAGE_TAG"

# # Replace the image in the deployment YAML
# sed -i "s|image:.*|image: \"$ECR_IMAGE_URI\"|g" "$DEPLOYMENT_YAML_PATH"

# # Confirmation
# echo "Updated $DEPLOYMENT_YAML_PATH with image: $ECR_IMAGE_URI"


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
