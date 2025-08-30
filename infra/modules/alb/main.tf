# =============================================================================
# APPLICATION LOAD BALANCER (ALB) - DISTRIBUIDOR DE TRÁFICO WEB
# =============================================================================
# El ALB es un balanceador de carga de capa 7 (aplicación) que distribuye
# el tráfico HTTP/HTTPS entre múltiples destinos (contenedores). Proporciona
# alta disponibilidad y puede realizar verificaciones de salud.
# =============================================================================

# Application Load Balancer principal
resource "aws_lb" "main" {
  name               = "${var.environment}-alb"
  internal           = false                      # false = accesible desde internet, true = solo interno
  load_balancer_type = "application"              # Tipo: application (L7), network (L4), o gateway
  security_groups    = var.vpc_security_group_ids # Grupos de seguridad (firewall) aplicados
  subnets            = var.public_subnet_ids      # Subredes públicas donde se despliega (multi-AZ)

  enable_deletion_protection = false # false = se puede eliminar, true = protegido contra eliminación

  tags = {
    Name = "${var.environment}-alb"
  }
}

# =============================================================================
# TARGET GROUP - GRUPO DE DESTINOS PARA EL BALANCEADOR
# =============================================================================
# Define un grupo de destinos (contenedores) hacia los cuales el ALB enviará
# el tráfico. Incluye configuración de health checks para verificar que los
# destinos estén funcionando correctamente.

# Grupo de destinos para contenedores WordPress
resource "aws_lb_target_group" "main" {
  name        = "${var.environment}-tg"
  port        = 80         # Puerto donde los contenedores escuchan peticiones
  protocol    = "HTTP"     # Protocolo de comunicación con los destinos
  vpc_id      = var.vpc_id # VPC donde están los destinos
  target_type = "ip"       # Tipo: "ip" para contenedores ECS, "instance" para EC2

  # Configuración de verificaciones de salud (health checks)
  health_check {
    enabled             = true           # Activar health checks
    healthy_threshold   = 2              # Número de checks exitosos para considerar destino sano
    interval            = 30             # Intervalo entre checks (segundos)
    matcher             = "200"          # Código de respuesta HTTP esperado
    path                = "/"            # Ruta a verificar (página principal de WordPress)
    port                = "traffic-port" # Puerto a verificar (mismo que el tráfico)
    protocol            = "HTTP"         # Protocolo para health checks
    timeout             = 5              # Tiempo máximo de espera por respuesta (segundos)
    unhealthy_threshold = 2              # Número de checks fallidos para considerar destino enfermo
  }

  tags = {
    Name = "${var.environment}-tg"
  }
}

# =============================================================================
# LISTENER - ESCUCHA PETICIONES EN EL PUERTO ESPECIFICADO
# =============================================================================
# El listener verifica las peticiones que llegan al ALB en un puerto específico
# y define qué hacer con ellas (enviarlas a qué target group).

# Listener HTTP - Escucha en puerto 80 y reenvía al target group
resource "aws_lb_listener" "main" {
  load_balancer_arn = aws_lb.main.arn # ARN del ALB donde aplicar este listener
  port              = "80"            # Puerto donde escuchar (80 = HTTP)
  protocol          = "HTTP"          # Protocolo a escuchar

  # Acción por defecto: reenviar todo el tráfico al target group
  default_action {
    type             = "forward"                    # Tipo de acción: forward (reenviar)
    target_group_arn = aws_lb_target_group.main.arn # Grupo de destinos donde enviar
  }
}