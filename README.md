<<<<<<< HEAD
# mod-technical-test
```
├── app/                               # Flask application code
│   ├── __init__.py                    # App initialization code
│   ├── app.py                         # Main entry point of the Flask app
│   ├── templates/                     # HTML templates for Flask (if using Jinja2)
│   ├── static/                        # Static files (CSS, JS, images)
│   ├── forms.py                       # Flask-WTF form definitions
│   ├── models.py                      # Database models (if any)
│   ├── requirements.txt               # Python dependencies
│   └── Dockerfile                     # Dockerfile to build the Flask app
│
├── terraform/                         # Terraform configuration
│   ├── main.tf                        # Main Terraform config file
│   ├── variables.tf                   # Terraform variables
│   ├── outputs.tf                     # Terraform outputs
│   ├── eks.tf                         # Terraform config for EKS cluster
│   ├── vpc.tf                         # Terraform config for VPC
│   ├── security.tf                    # Security group, IAM roles, and policies
│   ├── modules/                       # Reusable Terraform modules
│   │   └── eks-cluster/               # EKS cluster module
│   │       ├── main.tf                # EKS module main config
│   │       ├── variables.tf           # EKS module variables
│   │       ├── outputs.tf             # EKS module outputs
│   └── k8s/                           # Kubernetes resource definitions
│       ├── deployment.yaml            # Kubernetes Deployment for Flask app
│       └── service.yaml               # Kubernetes Service (LoadBalancer)
│
├── .github/                           # GitHub-related files
│   └── workflows/                     # GitHub Actions workflows
│       └── ci-cd.yaml                 # CI/CD pipeline for automated build, test, and deploy
│
├── k8s-deployment.yaml                # Kubernetes deployment file (optional)
├── k8s-service.yaml                   # Kubernetes service file (optional)
├── README.md                          # Documentation
└── .gitignore                         # Git ignore file

```

Sure! Below is a step-by-step guide to create a simple Python application that meets the requirements outlined in your challenge. We'll use the **Flask** framework to create a web application with a `/healthcheck` endpoint that returns application metadata in JSON format.

### Step 1: Setting Up the Project Structure

Create a directory for your project. Inside this directory, you will create the necessary files.

```bash
mkdir healthcheck-app
cd healthcheck-app
```

### Step 2: Create the Python Application

Create a file named `app.py` in the `healthcheck-app` directory with the following code:

```python
# app.py

from flask import Flask, jsonify
import os
import subprocess

app = Flask(__name__)

# Static information about the application
APP_VERSION = "1.0"
APP_DESCRIPTION = "Simple Health Check Application"

def get_last_commit_sha():
    """Get the last commit SHA from Git."""
    try:
        return subprocess.check_output(
            ["git", "rev-parse", "HEAD"]
        ).strip().decode('utf-8')
    except Exception as e:
        return str(e)

@app.route('/healthcheck', methods=['GET'])
def healthcheck():
    """Health check endpoint."""
    last_commit_sha = get_last_commit_sha()
    
    # Construct response
    response = {
        "myapplication": [
            {
                "version": APP_VERSION,
                "description": APP_DESCRIPTION,
                "lastcommitsha": last_commit_sha
            }
        ]
    }
    
    return jsonify(response)

if __name__ == '__main__':
    # Run the application
    port = os.getenv("APP_PORT", 10000)  # Default to port 10000 if not set
    app.run(host='0.0.0.0', port=port)
```

### Step 3: Requirements File

Create a `requirements.txt` file in the same directory to specify the dependencies:

```
flask
```

### Step 4: Containerize the Application

Next, create a `Dockerfile` in the same directory to containerize your application:

```dockerfile
# Dockerfile

# Use the official Python image from the Docker Hub
FROM python:3.10-slim

# Set the working directory
WORKDIR /app

# Copy the requirements file and install dependencies
COPY requirements.txt requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# Copy the application code to the container
COPY app.py .

# Expose the port the app runs on
EXPOSE 10000

# Command to run the application
CMD ["python", "app.py"]
```

### Step 5: Build the Docker Image

To build the Docker image, run the following command in your terminal from the project directory:

```bash
docker build -t healthcheck-app .
```

### Step 6: Run the Docker Container

After building the image, you can run the container:

```bash
docker run -d -p 10000:10000 healthcheck-app
```

### Step 7: Test the Health Check Endpoint

To test the `/healthcheck` endpoint, you can use `curl` or a web browser:

```bash
curl http://localhost:10000/healthcheck
```

You should see a response similar to:

```json
{
    "myapplication": [
        {
            "version": "1.0",
            "description": "Simple Health Check Application",
            "lastcommitsha": "abc57858585"  // This will show your last commit SHA
        }
    ]
}
```

### Step 8: Create a CI Pipeline

To create a simple CI pipeline, we'll use GitHub Actions. Create a directory named `.github/workflows` in your project directory and create a file named `ci.yml` inside it:

```yaml
# .github/workflows/ci.yml

name: CI

on:
  push:
    branches:
      - main  # Change this to your default branch
  pull_request:

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
    - name: Checkout code
      uses: actions/checkout@v2

    - name: Set up Python
      uses: actions/setup-python@v2
      with:
        python-version: '3.10'

    - name: Install dependencies
      run: |
        pip install -r requirements.txt

    - name: Run tests
      run: |
        # Add commands to run your tests here, e.g.:
        echo "No tests available"

    - name: Build Docker image
      run: |
        docker build -t healthcheck-app .

    - name: Run Docker container
      run: |
        docker run -d -p 10000:10000 healthcheck-app
```

### Step 9: Commit and Push Your Code

Now, commit your code and push it to your GitHub repository. Make sure to replace `<your-repo-url>` with your actual repository URL.

```bash
git init
git add .
git commit -m "Initial commit"
git remote add origin <your-repo-url>
git push -u origin main
```

### Conclusion

Now you have a simple Python application with the following capabilities:
- A `/healthcheck` endpoint that returns application metadata in JSON format.
- The application is containerized with Docker.
- A CI pipeline using GitHub Actions that builds the Docker image on each push to the repository.

Feel free to expand this application by adding tests, logging, and more advanced error handling as needed!
=======
# mod-technical_test
>>>>>>> 6856485da75b329e8b5e1fecd8d25b365b6cdf80
