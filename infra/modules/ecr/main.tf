# =============================================================================
# ECR (Elastic Container Registry)
# =============================================================================
# ECR es el servicio de AWS para almacenar imágenes Docker de forma privada.
# Similar a Docker Hub, pero dentro de tu cuenta AWS.

# Repositorio donde se guardarán las imágenes Docker de WordPress
resource "aws_ecr_repository" "main" {
  name                 = "${var.environment}-wordpress"
  image_tag_mutability = "MUTABLE" # Permite actualizar tags como 'latest'

  # Escaneo automático de vulnerabilidades
  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name        = "${var.environment}-wordpress-ecr"
    Environment = var.environment
  }
}

# Política de limpieza automática - Mantiene solo las últimas 10 imágenes
resource "aws_ecr_lifecycle_policy" "main" {
  repository = aws_ecr_repository.main.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last 10 images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 10
      }
      action = {
        type = "expire"
      }
    }]
  })
}
