# Technical Test: CI/CD Pipeline with Docker, ECR, Kubernetes, and GitHub Actions

## Challenge
The following test outlines the creation of a CI/CD pipeline for a Dockerized application deployed to AWS using **GitHub Actions**, **Amazon Elastic Container Registry (ECR)**, and **Kubernetes**. 

The test requirements are:
- Create a simple, containerized application with a `/healthcheck` endpoint.
- Implement a CI pipeline that handles:
  - Building and testing the application.
  - Pushing the container to ECR.
  - Deploying the application to an AWS Kubernetes cluster.
- The pipeline should trigger upon new code commits and manage different environments (development and production) based on the branch (`dev` or `main`).

The application for this example is built using **Python**.

The key elements implemented:
- **Healthcheck endpoint** returning application details in JSON format.
  - Application Version.
  - Description (static variable).
  - Last Commit SHA.

### API Example Response
```json
{
    "myapplication": [
        {
            "version": "1.0",
            "description" : "Gabriel Okom's pipeline test",
            "lastcommitsha": "abc57858585"
        }
    ]
}
```

Additional goals:
- Set up a CI pipeline with **GitHub Actions** that builds, tests, and deploys the application.
- Include unit tests and security checks.
- Write clear documentation to describe setup, usage, and risks.

---

## Solution Overview

This solution provides a CI/CD pipeline for a containerized Python application. The pipeline performs the following tasks:
- Build and test the application.
- Push the Docker image to AWS ECR.
- Deploy the application to an AWS-managed Kubernetes cluster (EKS).

---

## Example Solution

### Prerequisites
To use this solution, the following are required:
1. **AWS Account**: With permissions for ECR and EKS.
2. **GitHub Repository**: Fork or clone the repository to your own GitHub account.
3. **AWS CLI**: Ensure that AWS CLI is configured on your local machine.
4. **Kubectl**: Install `kubectl` to interact with Kubernetes.

#### Setup AWS Resources
Set up your AWS environment with ECR and Kubernetes:

1. **Authenticate AWS CLI**:
   ```bash
   aws configure
   aws ecr get-login-password --region <your-region> | docker login --username AWS --password-stdin <aws-account-id>.dkr.ecr.<your-region>.amazonaws.com
   ```

2. **Create ECR Repository**:
   ```bash
   aws ecr create-repository --repository-name <your-repo-name>
   ```

3. **Create EKS Cluster**:
   ```bash
   eksctl create cluster --name my-cluster --region <your-region> --nodes 2 --node-type t2.micro
   ```

---

### Local Build

A bash script (`build-gab-app.local.sh`) is provided to build the Docker container locally and run tests. It uses `pytest` for unit tests, which will automatically run during the Docker build process.

To build the application locally:
```bash
./gab-app.sh
```


Test the healthcheck endpoint:
```bash
curl http://localhost:8080/healthcheck
{
    "myapplication": [
        {
            "version": "local-docker",
            "description": "CI/CD pipeline test",
            "lastcommitsha": "31747bf46587c63040e085b2a854ad9c1a38074d"
        }
    ]
}
```

---

### CI/CD Pipeline

The pipeline uses **GitHub Actions** to build, test, and deploy the application automatically. The workflow is defined in the `ci.yml` file, which performs the following steps:
- **Build and Test**: The pipeline builds the Docker image and runs the unit tests.
- **Push to ECR**: The Docker image is pushed to the appropriate ECR repository.
- **Deploy to Kubernetes**: The application is deployed to an EKS cluster with a rolling update strategy.

#### Pipeline Workflow
1. **Trigger**: The pipeline triggers when new code is pushed to the `dev` or `main` branch.
2. **Build and Test**: 
   - Run unit tests using `pytest`.
   - Lint the code with `flake8`.
3. **Build Docker Image**:
   - Build the Docker image and tag it with the latest commit SHA.
4. **Push to ECR**: Push the Docker image to AWS ECR.
5. **Kubernetes Deployment**: Update the Kubernetes deployment to use the new Docker image.

```yaml
# Example steps in the pipeline (ci.yml)
- name: Build and tag Docker image
  run: docker build -t ${{ secrets.AWS_ACCOUNT_ID }}.dkr.ecr.${{ secrets.AWS_REGION }}.amazonaws.com/${{ secrets.ECR_REPOSITORY }}:${{ github.sha }} .

- name: Push Docker image to ECR
  run: docker push ${{ secrets.AWS_ACCOUNT_ID }}.dkr.ecr.${{ secrets.AWS_REGION }}.amazonaws.com/${{ secrets.ECR_REPOSITORY }}:${{ github.sha }}

- name: Deploy to Kubernetes
  run: kubectl set image deployment/myapp myapp=${{ secrets.AWS_ACCOUNT_ID }}.dkr.ecr.${{ secrets.AWS_REGION }}.amazonaws.com/${{ secrets.ECR_REPOSITORY }}:${{ github.sha }}
```

### Kubernetes Configuration

The Kubernetes deployment and service files (`kubernetes/deployment.yaml`) configure the application to be deployed in the cluster. A rolling update strategy is used to ensure zero downtime during deployment.

```yaml
# deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
spec:
  replicas: 2
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
    spec:
      containers:
      - name: myapp
        image: <aws-account-id>.dkr.ecr.<region>.amazonaws.com/<repository-name>:latest
        ports:
        - containerPort: 8080
```

---

### Known Risks
- **AWS Dependencies**: The pipeline heavily relies on AWS services like ECR and EKS, making it less portable.
- **Branch Restrictions**: Only `dev` and `main` branches trigger builds and deployments.
- **Kubernetes Availability**: The cluster is assumed to be in a healthy state. The pipeline does not check for Kubernetes cluster health before deploying.

---

### API Example
Once deployed, the application can be accessed through a load balancer created by Kubernetes. The healthcheck endpoint will return information about the application, including the latest commit SHA.

```bash
curl http://<load-balancer-ip>/healthcheck
```

---

### Branching Strategy
- **dev branch**: Used for development and testing environments.
- **main branch**: Used for production deployments.
- Feature branches can be merged into `dev` via pull requests. Deployments to production are done by merging `dev` into `main`.

