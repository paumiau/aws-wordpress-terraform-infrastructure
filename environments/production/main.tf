# =============================================================================
# CONFIGURACIÓN DEL ENTORNO DE PRODUCCIÓN
# =============================================================================
# Este archivo llama al módulo raíz con los valores específicos para producción.
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

# Llamada al módulo raíz con valores específicos de producción
module "wordpress_infrastructure" {
  source = "../../"

  # Valores específicos para el entorno de producción
  environment        = "production"
  aws_region         = "us-east-1"
  vpc_cidr           = "10.1.0.0/16"                              # Diferente CIDR para producción
  availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"] # 3 AZs para mayor disponibilidad

  # Configuración de base de datos - más recursos para producción
  db_instance_class = "db.t3.small" # Instancia más grande que desarrollo
  db_name           = "wordpress"
  db_username       = "admin"
  db_password       = var.db_password # Esta sí necesita ser variable para seguridad

  # Configuración de WordPress/ECS - más recursos para producción
  wordpress_image   = "wordpress:6.4" # Versión específica para producción
  ecs_desired_count = 3               # Más instancias para alta disponibilidad
  ecs_cpu           = 512             # Más CPU
  ecs_memory        = 1024            # Más memoria
}

# Variable para la contraseña de la base de datos
# Esta es la única variable que necesitamos declarar aquí porque debe venir
# del entorno (TF_VAR_db_password) por seguridad
variable "db_password" {
  description = "Database password - set via environment variable TF_VAR_db_password"
  type        = string
  sensitive   = true
}
