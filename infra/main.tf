# =============================================================================
# CONFIGURACIÓN PRINCIPAL DE TERRAFORM PARA WORDPRESS EN AWS
# =============================================================================
# Este archivo orquesta todos los servicios necesarios para desplegar WordPress
# en AWS usando una arquitectura de alta disponibilidad con contenedores
# =============================================================================
# NOTA: La configuración de Terraform y versiones está en terraform.tf

# Configuración del proveedor de AWS: especifica región y etiquetas por defecto
provider "aws" {
  region = var.aws_region # Región de AWS donde se desplegará la infraestructura

  # Etiquetas aplicadas automáticamente a todos los recursos creados
  default_tags {
    tags = {
      Environment = var.environment            # Entorno (dev, staging, prod)
      Project     = "wordpress-infrastructure" # Nombre del proyecto
      ManagedBy   = "terraform"                # Indica que es gestionado por Terraform
    }
  }
}

# =============================================================================
# MÓDULOS DE INFRAESTRUCTURA - ORDEN DE DESPLIEGUE IMPORTANTE
# =============================================================================

# VPC (Virtual Private Cloud) - La red virtual privada que aísla nuestra infraestructura
# Crea la red, subredes públicas/privadas, gateways de internet y NAT
module "vpc" {
  source = "./modules/vpc"

  environment        = var.environment        # Entorno para nombrar recursos
  vpc_cidr           = var.vpc_cidr           # Rango de IPs de la red (ej: 10.0.0.0/16)
  availability_zones = var.availability_zones # Zonas de disponibilidad para alta disponibilidad
}

# IAM (Identity and Access Management) - Roles y permisos para servicios de AWS
# Define qué servicios pueden acceder a qué recursos de forma segura
module "iam" {
  source      = "./modules/iam"
  environment = var.environment # Entorno para nombrar los roles
}

# RDS (Relational Database Service) - Base de datos MySQL gestionada para WordPress
# Proporciona una base de datos MySQL con backups automáticos y alta disponibilidad
module "rds" {
  source                 = "./modules/rds"
  environment            = var.environment                    # Entorno para nombrar recursos
  vpc_id                 = module.vpc.vpc_id                  # ID de la VPC donde crear la BD
  private_subnet_ids     = module.vpc.private_subnet_ids      # Subredes privadas para la BD
  db_instance_class      = var.db_instance_class              # Tamaño de la instancia (ej: db.t3.micro)
  db_name                = var.db_name                        # Nombre de la base de datos
  db_username            = var.db_username                    # Usuario administrador de la BD
  db_password            = var.db_password                    # Contraseña del administrador
  vpc_security_group_ids = [module.vpc.rds_security_group_id] # Grupos de seguridad (firewall)
}

# ALB (Application Load Balancer) - Balanceador de carga para distribuir tráfico
# Distribuye el tráfico web entre múltiples contenedores y proporciona alta disponibilidad
module "alb" {
  source                 = "./modules/alb"
  environment            = var.environment                    # Entorno para nombrar recursos
  vpc_id                 = module.vpc.vpc_id                  # ID de la VPC donde crear el ALB
  public_subnet_ids      = module.vpc.public_subnet_ids       # Subredes públicas para recibir tráfico
  vpc_security_group_ids = [module.vpc.alb_security_group_id] # Grupos de seguridad para el ALB
}

module "ecr" {
  source      = "./modules/ecr"
  environment = var.environment # Entorno para nombrar recursos
}

# ECS (Elastic Container Service) - Servicio de contenedores para ejecutar WordPress
# Ejecuta WordPress en contenedores Docker con escalado automático
module "ecs" {
  source              = "./modules/ecs"
  environment         = var.environment                        # Entorno para nombrar recursos
  vpc_id              = module.vpc.vpc_id                      # ID de la VPC
  private_subnet_ids  = module.vpc.private_subnet_ids          # Subredes privadas para contenedores
  target_group_arn    = module.alb.target_group_arn            # Grupo objetivo del balanceador
  task_execution_role = module.iam.ecs_task_execution_role_arn # Rol para ejecutar tareas ECS
  task_role           = module.iam.ecs_task_role_arn           # Rol para las tareas en ejecución
  security_group_ids  = [module.vpc.ecs_security_group_id]     # Grupos de seguridad para contenedores

  # Configuración específica de WordPress
  wordpress_image = var.wordpress_image    # Imagen Docker de WordPress a usar
  db_host         = module.rds.db_endpoint # Endpoint de la base de datos RDS
  db_name         = var.db_name            # Nombre de la base de datos
  db_username     = var.db_username        # Usuario de la base de datos
  db_password     = var.db_password        # Contraseña de la base de datos

  # Configuración de recursos para contenedores ECS
  desired_count = var.ecs_desired_count # Número deseado de contenedores ejecutándose
  cpu           = var.ecs_cpu           # CPU asignada a cada contenedor (en unidades)
  memory        = var.ecs_memory        # Memoria RAM asignada (en MB)

  # Registro ECR
  repository_url = module.ecr.repository_url # URL completa del repositorio ECR
}
