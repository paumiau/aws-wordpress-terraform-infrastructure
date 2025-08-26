# =============================================================================
# VPC (VIRTUAL PRIVATE CLOUD) - RED VIRTUAL PRIVADA EN AWS
# =============================================================================
# Una VPC es como tu propia red privada en AWS, aislada del resto de internet
# y de otros clientes de AWS. Es como tener tu propio centro de datos virtual.
# =============================================================================

# VPC Principal - La red virtual que contendrá todos nuestros recursos
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr        # Rango de direcciones IP (ej: 10.0.0.0/16 = 65,536 IPs)
  enable_dns_hostnames = true               # Permite usar nombres DNS dentro de la VPC
  enable_dns_support   = true               # Habilita resolución DNS para servicios AWS

  tags = {
    Name = "${var.environment}-vpc"
  }
}

# =============================================================================
# INTERNET GATEWAY - PUERTA DE ENTRADA A INTERNET
# =============================================================================
# El Internet Gateway permite que los recursos en subredes públicas puedan
# comunicarse con internet. Es como el router de tu casa que conecta tu red local
# con internet, pero para AWS.

# Internet Gateway - Permite acceso a internet desde la VPC
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id    # Se asocia a nuestra VPC principal

  tags = {
    Name = "${var.environment}-igw"
  }
}

# =============================================================================
# SUBREDES PÚBLICAS - DONDE SE UBICAN LOS RECURSOS CON ACCESO A INTERNET
# =============================================================================
# Las subredes públicas contienen recursos que necesitan ser accesibles desde
# internet, como balanceadores de carga. Están en diferentes zonas de
# disponibilidad para alta disponibilidad.

# Subredes públicas - Una en cada zona de disponibilidad para redundancia
resource "aws_subnet" "public" {
  count = length(var.availability_zones)  # Crear una subred por cada zona disponible

  vpc_id                  = aws_vpc.main.id                                    # VPC donde crear la subred
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index)         # Dividir la VPC en subredes /24
  availability_zone       = var.availability_zones[count.index]               # Zona de disponibilidad específica
  map_public_ip_on_launch = true                                             # Auto-asignar IP pública a instancias

  tags = {
    Name = "${var.environment}-public-subnet-${count.index + 1}"
    Type = "public"    # Etiqueta para identificar tipo de subred
  }
}

# =============================================================================
# SUBREDES PRIVADAS - DONDE SE UBICAN LOS RECURSOS SIN ACCESO DIRECTO A INTERNET
# =============================================================================
# Las subredes privadas contienen recursos que no necesitan ser accesibles
# directamente desde internet, como bases de datos y aplicaciones internas.
# Acceden a internet a través de NAT Gateways.

# Subredes privadas - Una en cada zona de disponibilidad
resource "aws_subnet" "private" {
  count = length(var.availability_zones)  # Crear una subred privada por zona

  vpc_id            = aws_vpc.main.id                                    # VPC donde crear la subred
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 10)    # Usar rangos IP diferentes (+10)
  availability_zone = var.availability_zones[count.index]               # Zona de disponibilidad específica

  tags = {
    Name = "${var.environment}-private-subnet-${count.index + 1}"
    Type = "private"   # Etiqueta para identificar tipo de subred
  }
}

# =============================================================================
# ELASTIC IPs - DIRECCIONES IP ESTÁTICAS PARA NAT GATEWAYS
# =============================================================================
# Elastic IP es una dirección IP pública estática que no cambia. Necesaria
# para los NAT Gateways que permiten salida a internet desde subredes privadas.

# Elastic IPs - Una IP estática por NAT Gateway
resource "aws_eip" "nat" {
  count = length(var.availability_zones)  # Una EIP por cada zona de disponibilidad

  domain = "vpc"      # Especifica que es para uso en VPC (no EC2 clásico)

  tags = {
    Name = "${var.environment}-nat-eip-${count.index + 1}"
  }

  depends_on = [aws_internet_gateway.main]  # Debe existir el IGW antes de crear la EIP
}

# =============================================================================
# NAT GATEWAYS - PERMITEN SALIDA A INTERNET DESDE SUBREDES PRIVADAS
# =============================================================================
# Los NAT Gateways permiten que los recursos en subredes privadas (como
# contenedores y bases de datos) puedan salir a internet para descargas
# y actualizaciones, pero sin permitir conexiones entrantes desde internet.

# NAT Gateways - Uno por zona de disponibilidad para redundancia
resource "aws_nat_gateway" "main" {
  count = length(var.availability_zones)  # Un NAT Gateway por zona

  allocation_id = aws_eip.nat[count.index].id      # IP estática asignada
  subnet_id     = aws_subnet.public[count.index].id # Se ubica en subred pública

  tags = {
    Name = "${var.environment}-nat-gateway-${count.index + 1}"
  }

  depends_on = [aws_internet_gateway.main]  # Requiere que exista el Internet Gateway
}

# =============================================================================
# TABLAS DE RUTAS - DEFINEN CÓMO SE ENRUTA EL TRÁFICO DE RED
# =============================================================================
# Las tablas de rutas determinan a dónde va el tráfico de red. Son como
# los mapas de carreteras que indican qué camino tomar para llegar al destino.

# Tabla de rutas para subredes públicas
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id    # Asociada a nuestra VPC

  # Ruta por defecto: todo el tráfico a internet va por el Internet Gateway
  route {
    cidr_block = "0.0.0.0/0"                   # Cualquier destino (0.0.0.0/0 = todo internet)
    gateway_id = aws_internet_gateway.main.id   # Vía Internet Gateway
  }

  tags = {
    Name = "${var.environment}-public-rt"
  }
}

# Tabla de rutas para subredes privadas (una por zona para usar su NAT Gateway local)
resource "aws_route_table" "private" {
  count = length(var.availability_zones)  # Una tabla de rutas privada por zona

  vpc_id = aws_vpc.main.id    # Asociada a nuestra VPC

  # Ruta por defecto: tráfico a internet va por el NAT Gateway correspondiente
  route {
    cidr_block     = "0.0.0.0/0"                        # Cualquier destino de internet
    nat_gateway_id = aws_nat_gateway.main[count.index].id # Vía NAT Gateway de la misma zona
  }

  tags = {
    Name = "${var.environment}-private-rt-${count.index + 1}"
  }
}

# =============================================================================
# ASOCIACIONES DE TABLAS DE RUTAS - CONECTAN SUBREDES CON SUS TABLAS DE RUTAS
# =============================================================================
# Las asociaciones vinculan cada subred con su tabla de rutas correspondiente.
# Sin esto, las subredes no sabrían cómo enrutar el tráfico.

# Asociar subredes públicas con la tabla de rutas pública
resource "aws_route_table_association" "public" {
  count = length(var.availability_zones)  # Una asociación por subred pública

  subnet_id      = aws_subnet.public[count.index].id  # Subred pública específica
  route_table_id = aws_route_table.public.id          # Tabla de rutas pública (compartida)
}

# Asociar subredes privadas con sus tablas de rutas privadas correspondientes
resource "aws_route_table_association" "private" {
  count = length(var.availability_zones)  # Una asociación por subred privada

  subnet_id      = aws_subnet.private[count.index].id    # Subred privada específica
  route_table_id = aws_route_table.private[count.index].id # Su tabla de rutas privada correspondiente
}

# =============================================================================
# GRUPOS DE SEGURIDAD - FIREWALLS VIRTUALES PARA CONTROLAR TRÁFICO
# =============================================================================
# Los grupos de seguridad actúan como firewalls virtuales que controlan
# qué tráfico puede entrar (ingress) y salir (egress) de los recursos.
# Son STATEFUL: si permites tráfico entrante, la respuesta se permite automáticamente.
# =============================================================================

# Grupo de seguridad para Application Load Balancer (ALB)
resource "aws_security_group" "alb" {
  name        = "${var.environment}-alb-sg"
  description = "Security group for ALB"
  vpc_id      = aws_vpc.main.id    # Asociado a nuestra VPC

  # REGLAS DE ENTRADA (INGRESS) - Qué tráfico puede entrar al ALB
  
  # Permitir tráfico HTTP desde cualquier lugar de internet
  ingress {
    from_port   = 80              # Puerto 80 (HTTP)
    to_port     = 80              # Puerto 80 (HTTP)
    protocol    = "tcp"           # Protocolo TCP
    cidr_blocks = ["0.0.0.0/0"]   # Desde cualquier IP de internet
  }

  # Permitir tráfico HTTPS desde cualquier lugar de internet
  ingress {
    from_port   = 443            # Puerto 443 (HTTPS)
    to_port     = 443            # Puerto 443 (HTTPS)
    protocol    = "tcp"          # Protocolo TCP
    cidr_blocks = ["0.0.0.0/0"]  # Desde cualquier IP de internet
  }

  # REGLAS DE SALIDA (EGRESS) - Qué tráfico puede salir del ALB
  
  # Permitir todo el tráfico de salida (necesario para comunicarse con contenedores)
  egress {
    from_port   = 0              # Desde puerto 0 (todos)
    to_port     = 0              # Hasta puerto 0 (todos)
    protocol    = "-1"            # Todos los protocolos (-1 = all)
    cidr_blocks = ["0.0.0.0/0"]  # Hacia cualquier destino
  }

  tags = {
    Name = "${var.environment}-alb-sg"
  }
}

# Grupo de seguridad para contenedores ECS (WordPress)
resource "aws_security_group" "ecs" {
  name        = "${var.environment}-ecs-sg"
  description = "Security group for ECS tasks"
  vpc_id      = aws_vpc.main.id    # Asociado a nuestra VPC

  # REGLAS DE ENTRADA - Solo permitir tráfico desde el ALB
  
  # Permitir tráfico HTTP solo desde el Application Load Balancer
  ingress {
    from_port       = 80                        # Puerto 80 (HTTP)
    to_port         = 80                        # Puerto 80 (HTTP)
    protocol        = "tcp"                     # Protocolo TCP
    security_groups = [aws_security_group.alb.id] # Solo desde el grupo de seguridad del ALB
  }
  # Nota: Esta configuración hace que solo el ALB pueda comunicarse con los contenedores,
  # no hay acceso directo desde internet. Es una práctica de seguridad muy buena.

  # REGLAS DE SALIDA - Permitir todo para descargas y conexiones a BD
  
  # Permitir todo el tráfico de salida (para conectarse a RDS, descargar actualizaciones, etc.)
  egress {
    from_port   = 0              # Desde puerto 0 (todos)
    to_port     = 0              # Hasta puerto 0 (todos)
    protocol    = "-1"            # Todos los protocolos
    cidr_blocks = ["0.0.0.0/0"]  # Hacia cualquier destino
  }

  tags = {
    Name = "${var.environment}-ecs-sg"
  }
}

# Grupo de seguridad para base de datos RDS (MySQL)
resource "aws_security_group" "rds" {
  name        = "${var.environment}-rds-sg"
  description = "Security group for RDS"
  vpc_id      = aws_vpc.main.id    # Asociado a nuestra VPC

  # REGLAS DE ENTRADA - Solo permitir conexiones desde contenedores ECS
  
  # Permitir conexiones MySQL solo desde los contenedores ECS
  ingress {
    from_port       = 3306                      # Puerto 3306 (MySQL/MariaDB)
    to_port         = 3306                      # Puerto 3306 (MySQL/MariaDB)
    protocol        = "tcp"                     # Protocolo TCP
    security_groups = [aws_security_group.ecs.id] # Solo desde contenedores ECS
  }
  # Nota: La base de datos solo acepta conexiones desde los contenedores WordPress,
  # nunca directamente desde internet. Esto es una práctica de seguridad fundamental.

  # REGLAS DE SALIDA - Normalmente no necesita salir, pero se permite por si acaso
  
  # Permitir tráfico de salida (generalmente no necesario para RDS)
  egress {
    from_port   = 0              # Desde puerto 0 (todos)
    to_port     = 0              # Hasta puerto 0 (todos)
    protocol    = "-1"            # Todos los protocolos
    cidr_blocks = ["0.0.0.0/0"]  # Hacia cualquier destino
  }

  tags = {
    Name = "${var.environment}-rds-sg"
  }
}