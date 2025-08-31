# =============================================================================
# ECR (ELASTIC CONTAINER REGISTRY) - SERVICIO DE REGISTRO DE AWS
# =============================================================================
# ECR permite guardar tus builds de contenedores Docker de forma segura.
# =============================================================================

# Repositorio ECR para las imágenes de WordPress
resource "aws_ecr_repository" "main" {
  name                 = "${var.environment}-wordpress"  # Nombre del repositorio de imágenes
  image_tag_mutability = "MUTABLE"                        # Permite sobrescribir tags existentes (ej: latest)

  # Configuración de escaneo de seguridad
  image_scanning_configuration {
    scan_on_push = true  # Escanear automáticamente cada imagen que se sube en busca de vulnerabilidades
  }

  tags = {
    Name = "${var.environment}-wordpress-ecr"
  }
}

# Política de ciclo de vida: limpia automáticamente imágenes viejas para ahorrar espacio y costos
# Es como un "limpiador automático" que borra imágenes antiguas
resource "aws_ecr_lifecycle_policy" "main" {
  repository = "aws_ecr_repository.name"  # Aplicar a qué repositorio

  # Configuración en formato JSON que define las reglas de limpieza
  policy = jsonencode({
    rules = [
      {
        rulePriority = 1                    # Prioridad de la regla (1 = más alta)
        description  = "Keep last 10 images" # Descripción de lo que hace
        selection = {
          tagStatus     = "tagged"          # Solo aplicar a imágenes con etiquetas
          tagPrefixList = ["v"]             # Solo a etiquetas que empiecen con "v" (ej: v1.0, v2.1)
          countType     = "imageCountMoreThan"  # Tipo de conteo: más de X imágenes
          countNumber   = 10                # Mantener solo las últimas 10 imágenes
        }
        action = {
          type = "expire"                   # Acción: eliminar las imágenes que cumplan los criterios
        }
      }
    ]
  })
}