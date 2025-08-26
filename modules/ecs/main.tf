# =============================================================================
# ECS (ELASTIC CONTAINER SERVICE) - SERVICIO DE CONTENEDORES DE AWS
# =============================================================================
# ECS permite ejecutar aplicaciones en contenedores Docker de forma gestionada.
# Se encarga de la orquestación, escalado, y mantenimiento de contenedores
# sin tener que gestionar servidores.
# =============================================================================

# Clúster ECS - Grupo lógico donde se ejecutarán los contenedores
resource "aws_ecs_cluster" "main" {
  name = "${var.environment}-cluster"    # Nombre del clúster

  # Configuración del clúster
  setting {
    name  = "containerInsights"    # Habilitar CloudWatch Container Insights
    value = "enabled"              # para monitoreo avanzado de contenedores
  }

  tags = {
    Name = "${var.environment}-cluster"
  }
}

# =============================================================================
# CAPACITY PROVIDERS - DEFINEN CÓMO SE EJECUTAN LOS CONTENEDORES
# =============================================================================
# Los capacity providers determinan qué infraestructura usar para ejecutar
# contenedores: Fargate (serverless) vs EC2 (servidores gestionados).

# Configuración de proveedores de capacidad para el clúster
resource "aws_ecs_cluster_capacity_providers" "main" {
  cluster_name = aws_ecs_cluster.main.name    # Clúster al que aplicar

  # Proveedores disponibles para este clúster
  capacity_providers = ["FARGATE", "FARGATE_SPOT"]    # FARGATE = serverless, FARGATE_SPOT = más barato

  # Estrategia por defecto: priorizar FARGATE normal
  default_capacity_provider_strategy {
    base              = 1            # Mínimo 1 tarea en FARGATE normal
    weight            = 100          # Peso relativo (100% preferencia)
    capacity_provider = "FARGATE"    # Usar FARGATE como principal
  }
}

# =============================================================================
# CLOUDWATCH LOGS - CENTRALIZACIÓN DE LOGS DE CONTENEDORES
# =============================================================================
# CloudWatch Logs recopila, almacena y permite consultar los logs generados
# por los contenedores. Es fundamental para debugging y monitoreo.

# Grupo de logs para los contenedores de WordPress
resource "aws_cloudwatch_log_group" "main" {
  name              = "/ecs/${var.environment}-wordpress"    # Nombre jerárquico del grupo
  retention_in_days = 14    # Retener logs por 14 días (después se eliminan automáticamente)

  tags = {
    Name = "${var.environment}-wordpress-logs"
  }
}

# =============================================================================
# TASK DEFINITION - DEFINE CÓMO EJECUTAR LOS CONTENEDORES
# =============================================================================
# La Task Definition es como un "plano" o "receta" que define:
# - Qué contenedores ejecutar
# - Qué recursos necesitan (CPU, memoria)
# - Cómo configurarlos (variables de entorno, puertos, logs)
# - Qué permisos tienen

# Definición de tarea para WordPress
resource "aws_ecs_task_definition" "main" {
  family                   = "${var.environment}-wordpress"    # Nombre de la familia de tareas
  network_mode             = "awsvpc"                         # Modo de red: cada tarea tiene su propia ENI
  requires_compatibilities = ["FARGATE"]                      # Compatible con Fargate (serverless)
  cpu                      = var.cpu                         # CPU asignada (256, 512, 1024, etc.)
  memory                   = var.memory                      # Memoria RAM asignada en MB
  execution_role_arn       = var.task_execution_role         # Rol para que ECS pueda ejecutar la tarea
  task_role_arn           = var.task_role                   # Rol para que la tarea acceda a otros servicios AWS

  # Definición de contenedores en formato JSON
  container_definitions = jsonencode([
    {
      name      = "wordpress"           # Nombre del contenedor
      image     = var.wordpress_image   # Imagen Docker a usar (ej: wordpress:latest)
      essential = true                  # Si este contenedor falla, toda la tarea falla

      # CONFIGURACIÓN DE PUERTOS - Cómo exponer el contenedor
      portMappings = [
        {
          containerPort = 80      # Puerto interno del contenedor (WordPress escucha en 80)
          protocol      = "tcp"   # Protocolo de red
        }
      ]

      # VARIABLES DE ENTORNO - Configuración pasada al contenedor WordPress
      environment = [
        {
          name  = "WORDPRESS_DB_HOST"      # Dirección del servidor de base de datos
          value = var.db_host
        },
        {
          name  = "WORDPRESS_DB_NAME"      # Nombre de la base de datos
          value = var.db_name
        },
        {
          name  = "WORDPRESS_DB_USER"      # Usuario para conectarse a la BD
          value = var.db_username
        },
        {
          name  = "WORDPRESS_DB_PASSWORD"  # Contraseña para la BD
          value = var.db_password
        }
      ]

      # CONFIGURACIÓN DE LOGS - Dónde enviar los logs del contenedor
      logConfiguration = {
        logDriver = "awslogs"    # Driver de logs: awslogs para CloudWatch
        options = {
          awslogs-group         = aws_cloudwatch_log_group.main.name    # Grupo de logs
          awslogs-region        = data.aws_region.current.name          # Región AWS
          awslogs-stream-prefix = "ecs"                                # Prefijo para streams
        }
      }
    }
  ])

  tags = {
    Name = "${var.environment}-wordpress-task"
  }
}

# =============================================================================
# ECS SERVICE - MANTIENE LOS CONTENEDORES EJECUTÁNDOSE
# =============================================================================
# El servicio ECS es responsable de:
# - Mantener el número deseado de contenedores ejecutándose
# - Reemplazar contenedores que fallen
# - Distribuir contenedores entre zonas de disponibilidad
# - Registrar/desregistrar contenedores en el load balancer
# - Gestionar despliegues de nuevas versiones

# Servicio ECS para WordPress
resource "aws_ecs_service" "main" {
  name            = "${var.environment}-wordpress-service"    # Nombre del servicio
  cluster         = aws_ecs_cluster.main.id                 # Clúster donde ejecutar
  task_definition = aws_ecs_task_definition.main.arn        # Qué tarea ejecutar
  desired_count   = var.desired_count                       # Número de contenedores deseados
  launch_type     = "FARGATE"                               # Usar Fargate (serverless)

  # CONFIGURACIÓN DE RED - Dónde y cómo ejecutar los contenedores
  network_configuration {
    security_groups  = var.security_group_ids    # Grupos de seguridad (firewall)
    subnets          = var.private_subnet_ids    # Subredes privadas (sin IP pública)
    assign_public_ip = false                     # No asignar IP pública (usar NAT Gateway)
  }

  # CONFIGURACIÓN DEL LOAD BALANCER - Cómo conectar con el ALB
  load_balancer {
    target_group_arn = var.target_group_arn    # Grupo de destinos del ALB
    container_name   = "wordpress"             # Nombre del contenedor en la task definition
    container_port   = 80                      # Puerto del contenedor a exponer
  }
  # Nota: Esta configuración hace que ECS automáticamente registre y desregistre
  # contenedores en el ALB según su estado de salud.

  depends_on = [var.target_group_arn]    # Asegurar que el target group existe primero

  tags = {
    Name = "${var.environment}-wordpress-service"
  }
}

# Data source para obtener la región actual de AWS
data "aws_region" "current" {}