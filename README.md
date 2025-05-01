# EC2-Based Web Application

This repository contains Terraform infrastructure code for an EC2-based web application with a Node.js backend and Angular frontend.

## Project Overview

This project implements a complete cloud infrastructure for a modern web application:

- **Frontend**: Angular application running on EC2 with Nginx
- **Backend**: Node.js API server running on a separate EC2 instance
- **Database**: Amazon RDS PostgreSQL database
- **CI/CD Pipeline**: Integrated with GitHub for automated deployments

## Infrastructure Components

The infrastructure is organized into modular components:

- **Networking**: VPC, public/private subnets, NAT Gateway, Internet Gateway
- **Compute**: EC2 instances, Application Load Balancer
- **Database**: RDS PostgreSQL
- **Storage**: S3 bucket for artifacts 
- **CI/CD**: Pipeline integration with GitHub
- **Monitoring**: CloudWatch alarms and metrics

## Getting Started

### Prerequisites

- Terraform ≥ 1.0.0
- AWS CLI configured with appropriate credentials
- Node.js and npm installed
- GitHub repository for the application code

### Running the Terraform API Server

The project includes a RESTful API for managing infrastructure. To start the API locally:

1. **Navigate to the API directory**:
   ```bash
   cd terraform-api
   ```

2. **Install dependencies**:
   ```bash
   npm install
   ```

3. **Start the server**:
   ```bash
   npm start
   ```

The API server will start on port 3000 by default. You can access the API at `http://localhost:3000`.

### Deployment

Once the API is running, you can use it to manage your infrastructure:

1. **Initialize Terraform**:
   ```bash
   curl -X POST http://localhost:3000/api/terraform/{templateName}/init
   ```

2. **Apply Terraform Configuration**:
   ```bash
   curl -X POST http://localhost:3000/api/terraform/{templateName}/apply
   ```

3. **Destroy Infrastructure**:
   ```bash
   curl -X POST http://localhost:3000/api/terraform/{templateName}/destroy
   ```

Replace `{templateName}` with a name that identifies your deployment (e.g., "dev", "staging", or "test").

### Manual Deployment

Alternatively, you can use Terraform CLI directly:

```bash
# Initialize Terraform
terraform init

# Create execution plan
terraform plan

# Apply changes
terraform apply

# Destroy infrastructure when done
terraform destroy
```

## Project Structure

```
terraform-ec2-web-app/ 
├── main.tf                  # Main entry point, provider configuration 
├── variables.tf             # Input variables 
├── outputs.tf               # Output variables 
├── terraform.tfvars         # Variable values (gitignored) 
├── modules/                 # Modularized components 
│   ├── networking/          # VPC, subnets, gateways, etc. 
│   ├── compute/             # EC2 instances, ALB, ASG 
│   ├── database/            # RDS PostgreSQL 
│   ├── storage/             # S3 bucket for artifacts 
│   ├── cicd/                # Pipeline, build, deploy 
│   └── monitoring/          # CloudWatch 
└── terraform-api/           # API for Terraform operations
    ├── terraform-api-server.js  # Main API server file
    ├── package.json            # Node.js dependencies
    └── README.md               # API documentation
```

## Configuration

Set required variables in `terraform.tfvars`:

```hcl
project_name        = "web-app"
environment         = "dev"
aws_region          = "us-east-1"
vpc_cidr            = "10.0.0.0/16"
backend_ami_id      = "ami-0123456789abcdef0"
frontend_ami_id     = "ami-0123456789abcdef0"
github_owner        = "your-github-username"
github_repo         = "your-repo-name"
```

## API Endpoints

- **GET /health**: Health check endpoint
- **GET /**: List all available endpoints
- **POST /api/terraform/:templateName/init**: Initialize Terraform for a specific template
- **POST /api/terraform/:templateName/apply**: Apply Terraform configuration for a specific template
- **POST /api/terraform/:templateName/destroy**: Destroy Terraform resources for a specific template
- **GET /api/bucket**: Get S3 bucket status
- **GET /api/templates**: List active templates
- **POST /api/cleanup**: Clean up all resources

## Testing

This project was created as Test Script 1 for Cloud Elevate Terra Test Scripts.