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
    │   ├── main.tf           # Module call
    │   ├── variables.tf      # Variable declarations
    │   ├── outputs.tf        # Output values
    │   ├── terraform.tfvars  # Variable values
    │   └── .env.example      # Environment variables example
    └── production/           # Production environment
        ├── main.tf           # Module call
        ├── variables.tf      # Variable declarations
        ├── outputs.tf        # Output values
        ├── terraform.tfvars  # Variable values
        └── .env.example      # Environment variables example
```

## Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform >= 1.0 installed
- Access to AWS account with necessary permissions
- Docker (optional, for local testing)

## Quick Start

### Manual Setup

#### Development Environment

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
   # Edit .env file and set:
   # TF_VAR_db_password=your_secure_password
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

#### Production Environment

1. Navigate to the production environment:
   ```bash
   cd environments/production
   ```

2. Follow the same steps as development but with production-specific values.

## Configuration

### Environment Variables

Set the following environment variable for database password:
- `TF_VAR_db_password`: Database password for MySQL (required)

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

## Common Terraform Commands

```bash
# Format Terraform files
terraform fmt -recursive

# Validate configuration
terraform validate

# Initialize Terraform
terraform init

# Plan changes
terraform plan

# Apply changes
terraform apply

# Apply without confirmation prompt
terraform apply -auto-approve

# Show current state
terraform show

# List resources
terraform state list

# Destroy infrastructure
terraform destroy
```

## Accessing WordPress

After deployment, get the load balancer DNS name:
```bash
terraform output wordpress_url
```

Visit the URL in your browser to complete WordPress installation.

## Security Features

- WordPress containers in private subnets
- RDS database in private subnets with no public access
- Security groups with minimal required access
- IAM roles following least privilege principle
- Encrypted RDS storage
- Sensitive variables marked with `sensitive = true`

## Monitoring

- CloudWatch logs for ECS containers at `/ecs/{environment}-wordpress`
- Container insights enabled for ECS cluster
- 14-day log retention

## Cost Optimization

- Fargate Spot capacity provider configured
- Auto-scaling RDS storage (20GB to 100GB)
- Appropriate instance sizes for each environment
- NAT Gateways in each AZ (can be reduced to 1 for cost savings)

## Local Development

For local WordPress development:
```bash
cd environments/local
docker-compose up -d
```

Access WordPress at http://localhost:8000

## Troubleshooting

### Common Issues

1. **Database connection errors**
   - Verify security groups allow traffic from ECS to RDS
   - Check database credentials in environment variables
   - Ensure RDS instance is in `available` state

2. **ECS tasks failing to start**
   - Check CloudWatch logs for the ECS service
   - Verify IAM roles have correct permissions
   - Ensure Docker image is accessible

3. **ALB health checks failing**
   - Verify WordPress is responding on port 80
   - Check security group rules
   - Review target group health check settings

## Best Practices

1. **State Management**: Use remote state backend (S3 + DynamoDB) for team collaboration
2. **Secrets**: Use AWS Secrets Manager or Parameter Store for production secrets
3. **Monitoring**: Set up CloudWatch alarms for critical metrics
4. **Backups**: Enable automated RDS backups with appropriate retention
5. **Updates**: Regularly update Terraform providers and modules

## Contributing

1. Create a feature branch
2. Make changes following Terraform best practices
3. Run `terraform fmt` and `terraform validate`
4. Test in development environment first
5. Submit pull request

## License

This project is licensed under the MIT License.