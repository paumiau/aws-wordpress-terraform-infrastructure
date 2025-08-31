# =============================================================================
# WordPress en AWS con Terraform
# =============================================================================
# Arquitectura: VPC → RDS (MySQL) → ECR (Docker) → ECS (Fargate) → ALB
# 
# Flujo de despliegue:
# 1. Crear la red (VPC)
# 2. Crear roles IAM
# 3. Crear base de datos (RDS)
# 4. Crear balanceador (ALB)
# 5. Crear registro de imágenes (ECR)
# 6. Desplegar contenedores (ECS)

# Proveedor AWS
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = var.environment
      Project     = "wordpress"
      ManagedBy   = "terraform"
    }
  }
}

# 1. VPC - Red privada virtual
module "vpc" {
  source = "./modules/vpc"

  environment        = var.environment
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
}

# 2. IAM - Roles y permisos
module "iam" {
  source      = "./modules/iam"
  environment = var.environment
}

# 3. RDS - Base de datos MySQL
module "rds" {
  source = "./modules/rds"

  environment            = var.environment
  vpc_id                 = module.vpc.vpc_id
  private_subnet_ids     = module.vpc.private_subnet_ids
  vpc_security_group_ids = [module.vpc.rds_security_group_id]
  
  db_instance_class = var.db_instance_class
  db_name           = var.db_name
  db_username       = var.db_username
  db_password       = var.db_password
}

# 4. ALB - Balanceador de carga
module "alb" {
  source = "./modules/alb"

  environment            = var.environment
  vpc_id                 = module.vpc.vpc_id
  public_subnet_ids      = module.vpc.public_subnet_ids
  vpc_security_group_ids = [module.vpc.alb_security_group_id]
}

# 5. ECR - Registro de imágenes Docker
module "ecr" {
  source      = "./modules/ecr"
  environment = var.environment
}

# 6. ECS - Servicio de contenedores
module "ecs" {
  source = "./modules/ecs"

  environment        = var.environment
  private_subnet_ids = module.vpc.private_subnet_ids
  security_group_ids = [module.vpc.ecs_security_group_id]
  
  # Integraciones
  repository_url      = module.ecr.repository_url
  target_group_arn    = module.alb.target_group_arn
  task_execution_role = module.iam.ecs_task_execution_role_arn
  task_role           = module.iam.ecs_task_role_arn
  
  # Base de datos
  db_host     = module.rds.db_endpoint
  db_name     = var.db_name
  db_username = var.db_username
  db_password = var.db_password
  
  # Configuración de contenedores
  desired_count = var.ecs_desired_count
  cpu           = var.ecs_cpu
  memory        = var.ecs_memory
}
