# =============================================================================
# ECS (Elastic Container Service)
# =============================================================================
# ECS ejecuta contenedores Docker en AWS de forma gestionada.
# Usamos Fargate para no tener que gestionar servidores.

# Clúster ECS - Agrupa todos nuestros contenedores
resource "aws_ecs_cluster" "main" {
  name = "${var.environment}-cluster"

  # Habilitar métricas detalladas en CloudWatch
  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name        = "${var.environment}-cluster"
    Environment = var.environment
  }
}

# Configuración para usar Fargate (serverless)
resource "aws_ecs_cluster_capacity_providers" "main" {
  cluster_name       = aws_ecs_cluster.main.name
  capacity_providers = ["FARGATE"]

  default_capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight            = 100
  }
}

# Logs de CloudWatch - Donde se guardan los logs de WordPress
resource "aws_cloudwatch_log_group" "main" {
  name              = "/ecs/${var.environment}-wordpress"
  retention_in_days = 14 # Mantener logs por 2 semanas

  tags = {
    Name        = "${var.environment}-wordpress-logs"
    Environment = var.environment
  }
}

# Task Definition - Define cómo ejecutar WordPress
resource "aws_ecs_task_definition" "main" {
  family                   = "${var.environment}-wordpress"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = var.task_execution_role
  task_role_arn            = var.task_role

  container_definitions = jsonencode([{
    name      = "wordpress"
    image     = "${var.repository_url}:${var.image_tag}"
    essential = true

    # Puerto donde escucha WordPress
    portMappings = [{
      containerPort = 80
    }]

    # Variables de entorno para conectar con la base de datos
    environment = [
      { name = "WORDPRESS_DB_HOST", value = var.db_host },
      { name = "WORDPRESS_DB_NAME", value = var.db_name },
      { name = "WORDPRESS_DB_USER", value = var.db_username },
      { name = "WORDPRESS_DB_PASSWORD", value = var.db_password }
    ]

    # Configuración de logs
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.main.name
        "awslogs-region"        = data.aws_region.current.name
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }])

  tags = {
    Name        = "${var.environment}-wordpress-task"
    Environment = var.environment
  }
}

# Service - Mantiene WordPress ejecutándose
resource "aws_ecs_service" "main" {
  name            = "${var.environment}-wordpress-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.main.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  # Configuración de red
  network_configuration {
    security_groups  = var.security_group_ids
    subnets          = var.private_subnet_ids
    assign_public_ip = false
  }

  # Conexión con el Load Balancer
  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = "wordpress"
    container_port   = 80
  }

  tags = {
    Name        = "${var.environment}-wordpress-service"
    Environment = var.environment
  }
}

# Data source para obtener la región actual de AWS
data "aws_region" "current" {}
