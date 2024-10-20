name: CI/CD Pipeline

on:
  push:
    branches:
      - dev
      - main
  pull_request:
    branches:
      - dev
      - main

jobs:
  build_and_test:
    runs-on: ubuntu-latest

    steps:
    - name: Checkout code
      uses: actions/checkout@v3

    - name: Set up Python
      uses: actions/setup-python@v4
      with:
        python-version: '3.x'

    - name: Install dependencies
      run: |
        python -m venv venv
        venv/bin/pip install -r requirements.txt
        venv/bin/pip install pytest flake8

    - name: Run Unit Tests
      run: |
        venv/bin/python -m pytest

    - name: Lint Test with Flake8
      run: |
        venv/bin/python -m flake8 .

  build_and_push_docker_image:
    needs: build_and_test
    runs-on: ubuntu-latest

    steps:
    - name: Checkout code
      uses: actions/checkout@v3

    - name: Set up AWS credentials
      uses: aws-actions/configure-aws-credentials@v2
      with:
        aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
        aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        aws-region: ${{ secrets.AWS_REGION }}

    - name: Log in to Amazon ECR
      id: login-ecr
      uses: aws-actions/amazon-ecr-login@v1

    - name: Set environment variables based on branch
      run: |
        if [ "${{ github.ref }}" == "refs/heads/main" ]; then
          echo "ECR_REPOSITORY=${{ secrets.ECR_REPOSITORY_PROD }}" >> $GITHUB_ENV
          echo "ENVIRONMENT=prod" >> $GITHUB_ENV
        else
          echo "ECR_REPOSITORY=${{ secrets.ECR_REPOSITORY_DEV }}" >> $GITHUB_ENV
          echo "ENVIRONMENT=dev" >> $GITHUB_ENV
        fi

    #  use the git commit hash for the image tag
    # - name: Set IMAGE_TAG
    #   run: |
    #     IMAGE_TAG=$(git rev-parse --short HEAD)
    #     echo "IMAGE_TAG=$IMAGE_TAG" >> $GITHUB_ENV
    - name: Set IMAGE_TAG to default
      run: |
       echo "IMAGE_TAG=latest" >> $GITHUB_ENV


    # - name: Build and tag Docker image
    #   run: |
    #     docker build -t ${{ secrets.AWS_ACCOUNT_ID }}.dkr.ecr.${{ secrets.AWS_REGION }}.amazonaws.com/$ECR_REPOSITORY:$IMAGE_TAG .

    # - name: Push Docker image to ECR
    #   run: |
    #     docker push ${{ secrets.AWS_ACCOUNT_ID }}.dkr.ecr.${{ secrets.AWS_REGION }}.amazonaws.com/$ECR_REPOSITORY:$IMAGE_TAG

    - name: Build and tag Docker image with 'latest'
      run: |
        docker build -t ${{ secrets.AWS_ACCOUNT_ID }}.dkr.ecr.${{ secrets.AWS_REGION }}.amazonaws.com/$ECR_REPOSITORY:latest .

    - name: Push Docker image to ECR with 'latest'
      run: |
        docker push ${{ secrets.AWS_ACCOUNT_ID }}.dkr.ecr.${{ secrets.AWS_REGION }}.amazonaws.com/$ECR_REPOSITORY:latest


  deploy_terraform_and_k8s:
    needs: build_and_push_docker_image
    runs-on: ubuntu-latest

    steps:
    - name: Checkout code
      uses: actions/checkout@v3

    - name: Set up AWS credentials
      uses: aws-actions/configure-aws-credentials@v2
      with:
        aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
        aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        aws-region: ${{ secrets.AWS_REGION }}

    - name: Install kubectl
      run: |
        curl -LO "https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl"
        chmod +x ./kubectl
        sudo mv ./kubectl /usr/local/bin/kubectl

    - name: Check kubectl version
      run: |
        kubectl version --client

    - name: Set up Terraform
      uses: hashicorp/setup-terraform@v2

    - name: Initialize Terraform
      run: terraform init
      working-directory: .github/workflows/terraform

    - name: Select Terraform Workspace
      run: |
        if [ "${{ github.ref }}" == "refs/heads/main" ]; then
          terraform workspace select prod
        else
          terraform workspace select dev
        fi
      working-directory: .github/workflows/terraform

    - name: Apply Terraform Changes
      run: terraform apply -auto-approve
      working-directory: .github/workflows/terraform

    - name: Update Kubeconfig for EKS Cluster
      run: |
        if [ "${{ github.ref }}" == "refs/heads/main" ]; then
          CLUSTER_NAME=eks-cluster-prod
        else
          CLUSTER_NAME=eks-cluster-dev
        fi
        aws eks update-kubeconfig --name $CLUSTER_NAME --region ${{ secrets.AWS_REGION }}
    
    - name: Set environment label
      run: |
        echo "ENVIRONMENT_LABEL=${{ github.ref == 'refs/heads/main' && 'prod' || 'dev' }}" >> $GITHUB_ENV

    - name: Apply service configuration
      run: |
        sed -i "s/environment: .*/environment: $ENVIRONMENT_LABEL/" ./kubernetes/deployment.yaml
        sed -i "s/environment: .*/environment: ${ENVIRONMENT_LABEL}/" ./kubernetes/service.yaml
    # - name: Replace placeholders in deployment.yaml
    #   run: |
    #     sed -i "s|IMAGE_URL|${{ secrets.AWS_ACCOUNT_ID }}.dkr.ecr.${{ secrets.AWS_REGION }}.amazonaws.com/$ECR_REPOSITORY:$IMAGE_TAG|" ./kubernetes/deployment.yaml
    #     sed -i "s|\${ENVIRONMENT}|${ENVIRONMENT}|" ./kubernetes/deployment.yaml
  
    - name: Install AWS CLI
      run: |
        sudo apt-get install -y awscli

    - name: Create ImagePullSecret
      run: |
        kubectl get secret gab-app-secret || \
        kubectl create secret docker-registry gab-app-secret \
        --docker-server=$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com \
        --docker-username=AWS \
        --docker-password=$(aws ecr get-login-password --region $AWS_REGION) \
        --docker-email=$MY_AWS_EMAIL

    # - name: Debug sed command
    #   run: |
    #     echo "sed -i 's|{{IMAGE_PLACEHOLDER}}|${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPOSITORY}:${IMAGE_TAG}|' ./kubernetes/deployment.yaml"

    # - name: Replace image placeholder in deployment.yaml
    #   run: |
    #       sed -i "s|{{IMAGE_PLACEHOLDER}}|${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPOSITORY}:${IMAGE_TAG}|" ./kubernetes/deployment.yaml
    #   env:
    #       AWS_ACCOUNT_ID: ${{ secrets.AWS_ACCOUNT_ID }}
    #       AWS_REGION: ${{ secrets.AWS_REGION }}
    #       ECR_REPOSITORY: ${{ secrets.ECR_REPOSITORY }}   

    
    - name: Update deployment.yaml with new ECR image
      run: |
        chmod +x ./kubernetes/k8s_script.sh
        ./kubernetes/k8s_script.sh ./kubernetes/deployment.yaml $ECR_REPOSITORY $AWS_REGION $IMAGE_TAG
      env:
        AWS_ACCOUNT_ID: ${{ secrets.AWS_ACCOUNT_ID }}
        ECR_REPOSITORY: ${{ secrets.ECR_REPOSITORY }}
        AWS_REGION: ${{ secrets.AWS_REGION }}
        IMAGE_TAG: latest

    - name: Deploy to Kubernetes
      run: |
        kubectl apply -f ./kubernetes/deployment.yaml
        kubectl apply -f ./kubernetes/service.yaml

    # - name: Patch Deployment with new image
    #   run: |
    #     kubectl set image deployment/gab-app-deployment gab-app-container=${{ secrets.$AWS_ACCOUNT_ID }}.dkr.ecr.${{ secrets.$AWS_REGION }}.amazonaws.com/$ECR_REPOSITORY:${IMAGE_TAG}
   
    - name: Get Kubernetes Nodes
      run: |
          echo "Getting Kubernetes nodes..."
          kubectl get nodes -o wide

    - name: Get Kubernetes Pods
      run: |
          echo "Getting Kubernetes pods..."
          kubectl get pods -o wide
    - name: Describe Kubernetes Pods
      run: |
          echo "Getting Kubernetes pods..."
          kubectl describe pods
     
    - name: Describe Kubernetes Nodes
      run: | 
          echo "Getting Kubernetes nodes details"
          kubectl describe nodes
    
    # - name: Get External IP
    #   id: get_external_ip
    #   run: |
    #       EXTERNAL_IP=$(kubectl get svc gab-app-service -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
    #       echo "EXTERNAL_IP=$EXTERNAL_IP"
    #       echo "External IP is $EXTERNAL_IP"

    # - name: Resolve External IP to IPv4
    #   id: resolve_ip
    #   run: |
    #       echo "Resolving external IP to IPv4..."
    #       IPV4_ADDR=$(dig +short $EXTERNAL_IP)
    #       if [ -z "$IPV4_ADDR" ]; then
    #         echo "Error: Unable to resolve external IP to IPv4"
    #         exit 1
    #       else
    #         echo "IPV4_ADDR=$IPV4_ADDR"
    #         echo "Resolved IPv4 Address is $IPV4_ADDR"
    #       fi

    # - name: Output IPv4 Address
    #   run: echo "IPv4 Address is ${{ env.IPV4_ADDR }}"