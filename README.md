<<<<<<< HEAD

=======
# Cloud Elevate - Terraform EC2 Web Application

![Terraform](https://img.shields.io/badge/Terraform-7B42BC?style=for-the-badge&logo=terraform&logoColor=white)
![AWS](https://img.shields.io/badge/AWS-FF9900?style=for-the-badge&logo=amazonwebservices&logoColor=white)
![Node.js](https://img.shields.io/badge/Node.js-339933?style=for-the-badge&logo=nodedotjs&logoColor=white)
![Angular](https://img.shields.io/badge/Angular-DD0031?style=for-the-badge&logo=angular&logoColor=white)

A complete Infrastructure as Code (IaC) solution for deploying a modern web application on AWS using Terraform. This project implements a scalable, secure, and automated cloud infrastructure for a full-stack web application with Angular frontend, Node.js backend, and PostgreSQL database.

## 🏗️ Architecture Overview

This project creates a complete cloud infrastructure with the following components:

- **Frontend**: Angular application deployed on EC2 with Nginx reverse proxy
- **Backend**: Node.js API server running on dedicated EC2 instances
- **Database**: Amazon RDS PostgreSQL for data persistence
- **Load Balancing**: Application Load Balancer for high availability
- **Networking**: Custom VPC with public/private subnets
- **CI/CD Pipeline**: Automated deployment integration with GitHub
- **Monitoring**: CloudWatch alarms and metrics
- **Storage**: S3 bucket for build artifacts and static assets

## 🚀 Features

### Infrastructure Components
- **Multi-tier Architecture**: Separation of frontend, backend, and database layers
- **High Availability**: Multi-AZ deployment with Application Load Balancer
- **Security**: Private subnets, security groups, IAM roles, and KMS encryption
- **Scalability**: Auto Scaling Groups for dynamic resource management
- **DNS Management**: Route 53 integration for domain management
- **Monitoring**: Comprehensive CloudWatch integration with custom alarms
- **Cost Optimization**: Efficient resource allocation and management
- **Encryption**: KMS-based encryption for data at rest and in transit

### API Management
- **RESTful API**: HTTP endpoints for infrastructure management
- **Template Management**: Support for multiple deployment environments
- **Automated Operations**: Initialize, apply, and destroy infrastructure programmatically
- **Health Monitoring**: Built-in health checks and status endpoints

## 🛠️ Prerequisites

Before getting started, ensure you have the following installed and configured:

- **Terraform** ≥ 1.0.0
- **AWS CLI** configured with appropriate credentials and permissions
- **Node.js** and npm for the API server
- **GitHub Account** for repository integration
- **AWS Account** with sufficient permissions for EC2, RDS, VPC, and S3

### Required AWS Permissions
Your AWS credentials should have permissions for:
- **EC2**: instances, security groups, key pairs, launch templates
- **VPC**: creation, subnets, internet gateways, NAT gateways, route tables
- **RDS**: database instances, subnet groups, parameter groups
- **S3**: bucket creation, object management, lifecycle policies
- **IAM**: roles, policies, instance profiles, service-linked roles
- **CloudWatch**: alarms, metrics, log groups, dashboards
- **Application Load Balancer**: target groups, listeners, rules
- **Route 53**: hosted zones, DNS records, health checks
- **KMS**: key creation, encryption policies, key rotation

## ⚡ Quick Start

### 1. Clone the Repository
```bash
git clone https://github.com/Jasmy-Elzha-Mathew-1715/terraform-ec2-web-app.git
cd terraform-ec2-web-app
```

### 2. Configure Environment Variables
Create a `.env` file in the root directory (this file is gitignored):

```bash
# AWS Configuration
AWS_REGION=us-east-1
AWS_PROFILE=your-aws-profile

# Terraform Configuration
TF_VAR_environment=dev
TF_VAR_project_name=cloud-elevate-app

# Application Configuration
NODE_ENV=development
API_PORT=3000
```

### 3. Configure Terraform Variables
Create a `terraform.tfvars` file with your specific configuration:

```hcl
# Project Configuration
project_name = "cloud-elevate-app"
environment  = "dev"
aws_region   = "us-east-1"

# Network Configuration
vpc_cidr = "10.0.0.0/16"

# AMI Configuration (use appropriate AMI IDs for your region)
backend_ami_id  = "ami-0123456789abcdef0"  # Ubuntu/Amazon Linux AMI
frontend_ami_id = "ami-0123456789abcdef0"  # Ubuntu/Amazon Linux AMI

# GitHub Integration
github_owner = "your-github-username"
github_repo  = "your-repository-name"

# Database Configuration
db_username = "admin"
db_password = "your-secure-password"  # Use AWS Secrets Manager in production
```

### 4. Deploy Using Terraform CLI
```bash
# Initialize Terraform
terraform init

# Review the execution plan
terraform plan

# Apply the configuration
terraform apply

# When ready to clean up
terraform destroy
```

### 5. Deploy Using the API Server

#### Start the API Server
```bash
cd terraform-api
node terraform-api-server.js
```

The API server will be available at `http://localhost:3000`

#### Use API Endpoints
```bash
# Initialize Terraform for a specific template
curl -X POST http://localhost:3000/api/terraform/dev/init

# Apply configuration
curl -X POST http://localhost:3000/api/terraform/dev/apply

# Check infrastructure status
curl -X GET http://localhost:3000/api/templates

# Destroy infrastructure
curl -X POST http://localhost:3000/api/terraform/dev/destroy
```

## 🔌 API Endpoints

The Terraform API provides the following endpoints:

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/health` | Health check endpoint |
| GET | `/` | List all available endpoints |
| POST | `/api/terraform/:templateName/init` | Initialize Terraform for a template |
| POST | `/api/terraform/:templateName/apply` | Apply Terraform configuration |
| POST | `/api/terraform/:templateName/destroy` | Destroy infrastructure resources |
| GET | `/api/bucket` | Get S3 bucket status |
| GET | `/api/templates` | List active deployment templates |
| POST | `/api/cleanup` | Clean up all resources |

### Example API Usage
```javascript
// Initialize infrastructure
const response = await fetch('http://localhost:3000/api/terraform/production/init', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' }
});

// Apply changes
await fetch('http://localhost:3000/api/terraform/production/apply', {
  method: 'POST'
});
```

## 🏗️ Module Details

### ALB (Application Load Balancer) Module
- Layer 7 load balancing with health checks
- SSL/TLS termination and certificate management
- Target groups for frontend and backend services
- Cross-zone load balancing for high availability
- Integration with Auto Scaling Groups

### Networking Module
- Creates custom VPC with configurable CIDR blocks
- Public and private subnets across multiple Availability Zones
- Internet Gateway for public subnet connectivity
- NAT Gateway for private subnet internet access
- Security Groups with least-privilege access rules
- Network ACLs for additional layer of security

### Compute Module
- EC2 instances for frontend and backend applications
- Launch templates with user data scripts for automated setup
- Auto Scaling Groups with scaling policies
- Security groups for network isolation

### Database Module
- RDS PostgreSQL instance with Multi-AZ deployment
- Database subnet groups in private subnets
- Automated backups and maintenance windows
- Parameter groups for performance optimization
- Security groups restricting database access to application tiers only

### Storage Module
- S3 bucket for application artifacts and static assets
- Versioning and encryption enabled
- Lifecycle policies for cost optimization
- Bucket policies for secure access control
- Integration with CloudFront (if applicable)

### DNS Module
- Route 53 hosted zones for domain management
- DNS records for load balancer endpoints
- Health checks for DNS failover
- Subdomain management for different environments

### Encryption Module
- Secret key creation and management

### IAM Module
- Service roles for EC2 instances
- Policies with least-privilege access
- Instance profiles for secure service access
- Cross-service assume role policies
- Service-linked roles where applicable

### CI/CD Module
- Integration with GitHub repositories
- Automated deployment pipelines
- Build artifact management
- Environment-specific configurations
- Integration with AWS CodePipeline/CodeBuild (if applicable)

### Monitoring Module
- CloudWatch alarms for key metrics (CPU, memory, disk, network)
- Log groups for application and system logs
- SNS topics for alert notifications
- Custom metrics and dashboards
- Cost and billing alarms

## 🔧 Configuration Options

### Environment Variables
```bash
export AWS_REGION=us-east-1
export AWS_PROFILE=your-profile
export TF_VAR_environment=dev
```

### Terraform Variables
Key variables you can customize in `terraform.tfvars`:

- `project_name`: Name prefix for all resources
- `environment`: Environment identifier (dev, staging, prod)
- `aws_region`: AWS region for deployment
- `vpc_cidr`: CIDR block for the VPC
- `instance_type`: EC2 instance type for applications
- `db_instance_class`: RDS instance class
- `enable_monitoring`: Enable/disable CloudWatch monitoring

## 🔒 Security Best Practices

This project implements several security best practices:

- **Network Isolation**: Private subnets for backend and database
- **Security Groups**: Restrictive ingress/egress rules
- **IAM Roles**: Least-privilege access for EC2 instances
- **Encryption**: EBS and RDS encryption at rest
- **Secrets Management**: Use AWS Secrets Manager for sensitive data
- **VPC Flow Logs**: Network traffic monitoring

## 📊 Monitoring and Logging

The infrastructure includes comprehensive monitoring:

- **CloudWatch Metrics**: CPU, memory, disk, and network monitoring
- **Application Logs**: Centralized logging for troubleshooting
- **Health Checks**: Load balancer and instance health monitoring
- **Alarms**: Automated alerts for critical issues
- **Cost Monitoring**: Resource usage and cost optimization

## 🚀 Deployment Strategies

### Blue-Green Deployment
Use the API to manage multiple environments:
```bash
# Deploy to staging
curl -X POST http://localhost:3000/api/terraform/staging/apply

# Test and validate
# Switch traffic to production
curl -X POST http://localhost:3000/api/terraform/production/apply
```

### Rolling Updates
Leverage Auto Scaling Groups for zero-downtime deployments with updated launch templates.

## 🧪 Testing

### Infrastructure Testing
```bash
# Validate Terraform configuration
terraform validate

# Check formatting
terraform fmt -check

# Security scanning (if using tools like tfsec)
tfsec .
```

### API Testing
```bash
# Test API endpoints
npm test  # If test scripts are configured

# Manual health check
curl http://localhost:3000/health
```

## 🔄 CI/CD Integration

This project is designed to integrate with CI/CD pipelines:

### GitHub Actions Example
```yaml
name: Deploy Infrastructure
on:
  push:
    branches: [main]
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v1
      - name: Terraform Apply
        run: terraform apply -auto-approve
```

## 🐛 Troubleshooting

### Common Issues

1. **AWS Credentials**: Ensure AWS CLI is configured correctly
2. **Terraform State**: Use remote state backend for team collaboration
3. **Resource Limits**: Check AWS service limits for your account
4. **Network Connectivity**: Verify security group rules and routing

### Debug Commands
```bash
# Enable Terraform debug logging
export TF_LOG=DEBUG

# Check AWS credentials
aws sts get-caller-identity

# Validate configuration
terraform validate
```

## 📈 Performance Optimization

- **Instance Sizing**: Right-size EC2 instances based on workload
- **Auto Scaling**: Configure appropriate scaling policies
- **Database**: Optimize RDS instance class and storage type
- **CDN**: Consider CloudFront for static content delivery
- **Caching**: Implement application-level caching strategies

## 💰 Cost Management

- **Resource Tagging**: Consistent tagging for cost allocation
- **Instance Scheduling**: Stop non-production instances during off-hours
- **Reserved Instances**: Use RIs for predictable workloads
- **Monitoring**: Set up billing alerts and cost budgets

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is part of the Cloud Elevate Terra Test Scripts initiative.

## 👥 Authors

- **Jasmy Elzha Mathew** - Initial work - [GitHub Profile](https://github.com/Jasmy-Elzha-Mathew-1715)

## 🙏 Acknowledgments

This project was created as **Test Script 1** for Cloud Elevate Terra Test Scripts, demonstrating modern Infrastructure as Code practices with Terraform and AWS.

## 📞 Support

For support and questions:
- Create an issue in the GitHub repository
- Review the troubleshooting section above
- Check AWS and Terraform documentation

---

**Note**: This is a demonstration project for educational purposes. For production deployments, ensure proper security reviews, compliance checks, and testing procedures are followed.
>>>>>>> e6ecb4e (Updated ReadMe File)
