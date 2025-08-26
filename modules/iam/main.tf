# =============================================================================
# IAM (IDENTITY AND ACCESS MANAGEMENT) - GESTIÓN DE PERMISOS Y ACCESOS
# =============================================================================
# IAM permite definir quién puede hacer qué en AWS de forma segura.
# Los roles permiten que servicios de AWS accedan a otros servicios
# sin necesidad de credenciales hardcodeadas.
# =============================================================================

# Documento de política que permite al servicio ECS asumir el rol de ejecución
data "aws_iam_policy_document" "ecs_task_execution_role" {
  statement {
    actions = ["sts:AssumeRole"]    # Acción: permitir asumir este rol

    # Quién puede asumir este rol
    principals {
      type        = "Service"                     # Tipo: servicio de AWS
      identifiers = ["ecs-tasks.amazonaws.com"]  # El servicio ECS puede asumir este rol
    }
  }
}

# =============================================================================
# ROLES IAM PARA ECS - PERMISOS PARA EJECUTAR Y GESTIONAR CONTENEDORES
# =============================================================================
# ECS necesita dos tipos de roles:
# 1. Task Execution Role: Para que ECS pueda crear/iniciar contenedores
# 2. Task Role: Para que los contenedores accedan a otros servicios AWS

# Rol de ejecución - Permite a ECS gestionar el ciclo de vida de contenedores
resource "aws_iam_role" "ecs_task_execution_role" {
  name               = "${var.environment}-ecs-task-execution-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_execution_role.json

  tags = {
    Name = "${var.environment}-ecs-task-execution-role"
  }
}

# Adjuntar política gestionada por AWS al rol de ejecución
resource "aws_iam_role_policy_attachment" "ecs_task_execution_role" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
# Esta política permite:
# - Descargar imágenes de ECR (Elastic Container Registry)
# - Escribir logs a CloudWatch
# - Acceder a parámetros de Systems Manager (si se usan)

# Documento de política que permite al servicio ECS asumir el rol de tarea
data "aws_iam_policy_document" "ecs_task_role" {
  statement {
    actions = ["sts:AssumeRole"]    # Acción: permitir asumir este rol

    # Quién puede asumir este rol
    principals {
      type        = "Service"                     # Tipo: servicio de AWS
      identifiers = ["ecs-tasks.amazonaws.com"]  # El servicio ECS puede asumir este rol
    }
  }
}

# Rol de tarea - Permisos que tendrán los contenedores ejecutándose
resource "aws_iam_role" "ecs_task_role" {
  name               = "${var.environment}-ecs-task-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_role.json

  tags = {
    Name = "${var.environment}-ecs-task-role"
  }
}

# =============================================================================
# POLÍTICAS PERSONALIZADAS - PERMISOS ESPECÍFICOS PARA NUESTROS CONTENEDORES
# =============================================================================
# Definimos políticas personalizadas para otorgar permisos específicos
# que nuestros contenedores WordPress necesitan.

# Política personalizada para que los contenedores puedan escribir logs
data "aws_iam_policy_document" "ecs_task_policy" {
  statement {
    effect = "Allow"    # Permitir estas acciones
    actions = [
      "logs:CreateLogGroup",     # Crear grupos de logs
      "logs:CreateLogStream",    # Crear streams de logs
      "logs:PutLogEvents"        # Escribir eventos de log
    ]
    resources = ["*"]    # En todos los recursos (se podría restringir más)
  }
}

# Adjuntar la política personalizada al rol de tarea
resource "aws_iam_role_policy" "ecs_task_policy" {
  name   = "${var.environment}-ecs-task-policy"
  role   = aws_iam_role.ecs_task_role.id                    # Rol al que adjuntar
  policy = data.aws_iam_policy_document.ecs_task_policy.json # Política definida arriba
}
# Nota: Esto permite que los contenedores WordPress escriban sus propios logs
# directamente a CloudWatch si fuera necesario (además del logging via ECS).