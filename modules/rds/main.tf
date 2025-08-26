# =============================================================================
# RDS (RELATIONAL DATABASE SERVICE) - BASE DE DATOS GESTIONADA
# =============================================================================
# RDS es un servicio de base de datos gestionado que se encarga de:
# - Instalación y configuración del motor de BD
# - Backups automáticos
# - Aplicación de parches de seguridad
# - Monitoreo y alertas
# - Escalado de recursos
# - Alta disponibilidad con Multi-AZ
# =============================================================================

# Grupo de subredes para RDS - Define dónde puede ubicarse la base de datos
resource "aws_db_subnet_group" "main" {
  name       = "${var.environment}-db-subnet-group"
  subnet_ids = var.private_subnet_ids    # Solo subredes privadas (no accesible desde internet)

  tags = {
    Name = "${var.environment}-db-subnet-group"
  }
}

# =============================================================================
# PARAMETER GROUP - CONFIGURACIÓN PERSONALIZADA DE LA BASE DE DATOS
# =============================================================================
# Permite modificar configuraciones del motor de base de datos sin necesidad
# de acceso directo al servidor. Útil para optimización de rendimiento.

# Grupo de parámetros personalizado para MySQL 8.0
resource "aws_db_parameter_group" "main" {
  family = "mysql8.0"                               # Familia del motor de BD
  name   = "${var.environment}-db-params"

  # Configuración personalizada del buffer pool de InnoDB
  parameter {
    name  = "innodb_buffer_pool_size"                # Parámetro a modificar
    value = "{DBInstanceClassMemory*3/4}"            # Usar 75% de la memoria para el buffer pool
  }
  # Nota: El buffer pool es la memoria caché donde InnoDB almacena datos y índices.
  # Un tamaño mayor mejora el rendimiento al reducir las lecturas de disco.

  tags = {
    Name = "${var.environment}-db-params"
  }
}

# =============================================================================
# INSTANCIA RDS - LA BASE DE DATOS MYSQL PRINCIPAL
# =============================================================================
# Esta es la instancia real de base de datos que almacenará todos los datos
# de WordPress: posts, páginas, usuarios, configuraciones, etc.

# Instancia de base de datos MySQL para WordPress
resource "aws_db_instance" "main" {
  # IDENTIFICACIÓN Y MOTOR
  identifier     = "${var.environment}-wordpress-db"    # Nombre único de la instancia
  engine         = "mysql"                              # Motor de base de datos
  engine_version = "8.0"                                # Versión específica de MySQL
  instance_class = var.db_instance_class                # Tamaño de la instancia (ej: db.t3.micro)

  # CONFIGURACIÓN DE ALMACENAMIENTO
  allocated_storage     = 20       # Almacenamiento inicial en GB
  max_allocated_storage = 100      # Máximo almacenamiento con auto-scaling (GB)
  storage_type          = "gp2"    # Tipo: gp2 (General Purpose SSD), gp3, io1, etc.
  storage_encrypted     = true     # Cifrar almacenamiento en reposo

  # CREDENCIALES DE ACCESO
  db_name  = var.db_name       # Nombre de la base de datos inicial
  username = var.db_username   # Usuario administrador
  password = var.db_password   # Contraseña del administrador

  # CONFIGURACIÓN DE RED Y SEGURIDAD
  vpc_security_group_ids = var.vpc_security_group_ids    # Grupos de seguridad (firewall)
  db_subnet_group_name   = aws_db_subnet_group.main.name # Subredes donde puede estar la BD
  parameter_group_name   = aws_db_parameter_group.main.name # Configuración personalizada

  # CONFIGURACIÓN DE BACKUPS Y MANTENIMIENTO
  backup_retention_period = 7                        # Retener backups por 7 días
  backup_window          = "03:00-04:00"             # Ventana de backup (UTC): 3-4 AM
  maintenance_window     = "sun:04:00-sun:05:00"     # Ventana de mantenimiento: domingo 4-5 AM

  # CONFIGURACIÓN DE ELIMINACIÓN
  skip_final_snapshot = true     # No crear snapshot final al eliminar (para desarrollo)
  deletion_protection = false    # Permitir eliminación (para desarrollo)
  
  # NOTA IMPORTANTE: En producción cambiar a:
  # skip_final_snapshot = false
  # deletion_protection = true

  tags = {
    Name = "${var.environment}-wordpress-db"
  }
}