# =============================================================================
# CONFIGURACIÓN DEL ENTORNO DE DESARROLLO
# =============================================================================
# Este archivo llama al módulo raíz con los valores específicos para desarrollo.
# No necesitamos redeclarar variables, solo pasar los valores directamente.
# =============================================================================

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Llamada al módulo raíz con valores específicos de desarrollo
module "wordpress_infrastructure" {
  source = "../../"

  # Valores específicos para el entorno de desarrollo
  environment        = "development"
  aws_region         = "us-east-1"
  vpc_cidr           = "10.0.0.0/16"
  availability_zones = ["us-east-1a", "us-east-1b"]

  # Configuración de base de datos
  db_instance_class = "db.t3.micro"
  db_name           = "wordpress"
  db_username       = "admin"
  db_password       = var.db_password # Esta sí necesita ser variable por seguridad

  # Configuración de ECS
  ecs_desired_count = 1
  ecs_cpu           = 256
  ecs_memory        = 512
}

# Variable para la contraseña de la base de datos
# Declarada como variable de entorno (TF_VAR_db_password) por seguridad
variable "db_password" {
  description = "Database password - set via environment variable TF_VAR_db_password"
  type        = string
  sensitive   = true
}
