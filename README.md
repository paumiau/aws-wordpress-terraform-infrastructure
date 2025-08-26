# WordPress Infrastructure on AWS with Terraform

This project deploys a scalable WordPress infrastructure on AWS using Terraform modules and ECS Fargate containers.

## Architecture

- **VPC**: Custom VPC with public and private subnets across multiple AZs
- **ECS**: WordPress containers running on Fargate
- **RDS**: MySQL database in private subnets
- **ALB**: Application Load Balancer for traffic distribution
- **IAM**: Proper roles and policies for ECS tasks

## Project Structure

```
├── main.tf                    # Root module
├── variables.tf               # Root variables
├── outputs.tf                 # Root outputs
├── modules/                   # Terraform modules
│   ├── vpc/                   # VPC, subnets, security groups
│   ├── iam/                   # IAM roles and policies
│   ├── rds/                   # RDS MySQL database
│   ├── alb/                   # Application Load Balancer
│   └── ecs/                   # ECS cluster and service
└── environments/              # Environment configurations
    ├── development/           # Development environment
    └── production/            # Production environment
```

## Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform >= 1.0 installed
- Access to AWS account with necessary permissions

## Environment Setup

### Development Environment

1. Navigate to the development environment:
   ```bash
   cd environments/development
   ```

2. Create environment file:
   ```bash
   cp .env.example .env
   ```

3. Set your database password in `.env`:
   ```bash
   echo "TF_VAR_db_password=your_secure_password" > .env
   ```

4. Load environment variables:
   ```bash
   source .env
   ```

5. Initialize and deploy:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

### Production Environment

1. Navigate to the production environment:
   ```bash
   cd environments/production
   ```

2. Follow the same steps as development but with production-specific values.

## Configuration

### Environment Variables

Set the following environment variable for database password:
- `TF_VAR_db_password`: Database password for MySQL

### Environment Differences

**Development:**
- Single ECS task
- db.t3.micro RDS instance
- 256 CPU / 512 MB memory
- VPC CIDR: 10.0.0.0/16

**Production:**
- 3 ECS tasks for high availability
- db.t3.small RDS instance
- 512 CPU / 1024 MB memory
- VPC CIDR: 10.1.0.0/16

## Deployment Commands

```bash
# Initialize Terraform
terraform init

# Plan changes
terraform plan

# Apply changes
terraform apply

# Destroy infrastructure
terraform destroy
```

## Accessing WordPress

After deployment, get the load balancer DNS name:
```bash
terraform output wordpress_url
```

## Security Features

- WordPress containers in private subnets
- RDS database in private subnets
- Security groups with minimal required access
- IAM roles with least privilege principle
- Encrypted RDS storage

## Monitoring

- CloudWatch logs for ECS containers
- Container insights enabled for ECS cluster

## Cost Optimization

- Fargate Spot capacity provider configured
- Auto-scaling RDS storage
- Appropriate instance sizes for each environment