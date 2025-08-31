# 🚀 WordPress en AWS con Terraform

Proyecto educativo para aprender a desplegar WordPress en AWS usando Terraform, Docker y servicios gestionados.

## 📚 Arquitectura

```
Internet → ALB (Balanceador) → ECS Fargate (WordPress) → RDS MySQL
                                        ↓
                                   ECR (Imágenes Docker)
```

## 🏗️ Componentes

### 1. **VPC** (Red Virtual)
- Subredes públicas: Para el balanceador de carga
- Subredes privadas: Para contenedores y base de datos
- NAT Gateway: Para que los contenedores accedan a internet

### 2. **RDS** (Base de Datos)
- MySQL 8.0 gestionado por AWS
- Backups automáticos
- Alta disponibilidad opcional

### 3. **ECR** (Registro de Docker)
- Almacena las imágenes Docker de WordPress
- Escaneo automático de vulnerabilidades
- Limpieza automática de imágenes antiguas

### 4. **ECS Fargate** (Contenedores)
- Ejecuta WordPress sin gestionar servidores
- Escalado automático
- Logs centralizados en CloudWatch

### 5. **ALB** (Balanceador de Carga)
- Distribuye tráfico entre contenedores
- Health checks automáticos
- SSL/TLS opcional

## 🛠️ Requisitos Previos

1. **AWS CLI** configurado
2. **Terraform** >= 1.0
3. **Docker** instalado
4. **Cuenta AWS** con permisos adecuados

## 📦 Estructura del Proyecto

```
infra/
├── main.tf              # Configuración principal
├── variables.tf         # Variables de entrada
├── outputs.tf          # Valores de salida
├── modules/
│   ├── vpc/           # Red virtual
│   ├── iam/           # Roles y permisos
│   ├── rds/           # Base de datos
│   ├── alb/           # Balanceador
│   ├── ecr/           # Registro Docker
│   └── ecs/           # Contenedores
└── environments/      # Configuraciones por entorno
```

## 🚀 Despliegue Paso a Paso

### 1. Configurar Variables

Crea un archivo `terraform.tfvars`:

```hcl
environment = "development"
aws_region  = "us-east-1"
db_password = "TuPasswordSeguro123!"  # Mínimo 8 caracteres
```

### 2. Inicializar Terraform

```bash
cd infra/
terraform init
```

### 3. Planificar Cambios

```bash
terraform plan
```

### 4. Crear Infraestructura

```bash
terraform apply
```

### 5. Construir y Subir Imagen Docker

```bash
# Obtener URL del repositorio ECR
ECR_URL=$(terraform output -raw ecr_repository_url)

# Login a ECR
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin $ECR_URL

# Construir imagen
cd ../app/
docker build -t wordpress .

# Etiquetar y subir
docker tag wordpress:latest $ECR_URL:latest
docker push $ECR_URL:latest
```

### 6. Actualizar ECS con Nueva Imagen

```bash
# Volver al directorio de Terraform
cd ../infra/

# Forzar nuevo despliegue
aws ecs update-service \
  --cluster development-cluster \
  --service development-wordpress-service \
  --force-new-deployment
```

### 7. Acceder a WordPress

```bash
# Obtener URL
terraform output wordpress_url
```

## 📊 Monitoreo

### CloudWatch Logs
- Logs de contenedores: `/ecs/development-wordpress`
- Métricas de ECS: CloudWatch → Container Insights

### Comandos Útiles

```bash
# Ver logs
aws logs tail /ecs/development-wordpress --follow

# Ver estado del servicio
aws ecs describe-services \
  --cluster development-cluster \
  --services development-wordpress-service

# Escalar servicio
aws ecs update-service \
  --cluster development-cluster \
  --service development-wordpress-service \
  --desired-count 3
```

## 💰 Costos Estimados (us-east-1)

| Servicio | Configuración | Costo Mensual |
|----------|--------------|---------------|
| VPC | NAT Gateway | ~$45 |
| RDS | db.t3.micro | ~$15 |
| ECS Fargate | 2x (0.25 vCPU, 0.5GB) | ~$18 |
| ALB | 1 balanceador | ~$23 |
| ECR | < 1GB | ~$0.10 |
| **Total** | | **~$101/mes** |

*Nota: Costos aproximados, pueden variar según uso y región.*

## 🧹 Limpieza

Para evitar cargos, destruye los recursos cuando termines:

```bash
terraform destroy
```

## 📖 Conceptos Clave para Aprender

### Terraform
- **Módulos**: Componentes reutilizables
- **Variables**: Parametrización
- **Outputs**: Valores de salida
- **State**: Estado de la infraestructura

### AWS
- **VPC**: Aislamiento de red
- **Security Groups**: Firewall a nivel de instancia
- **IAM Roles**: Permisos sin credenciales
- **Fargate**: Contenedores serverless

### Docker
- **Dockerfile**: Definición de imagen
- **ECR**: Registro privado de AWS
- **Tags**: Versionado de imágenes

## 🔒 Mejoras de Seguridad Recomendadas

1. **Secrets Manager**: Para contraseñas de BD
2. **HTTPS**: Certificado SSL en ALB
3. **WAF**: Firewall de aplicaciones web
4. **VPN**: Acceso seguro a recursos privados
5. **Backup**: Snapshots automáticos de RDS

## 🤝 Contribuir

Este es un proyecto educativo. Si encuentras mejoras:

1. Fork el repositorio
2. Crea una rama (`git checkout -b mejora/MiMejora`)
3. Commit cambios (`git commit -m 'Añadir MiMejora'`)
4. Push a la rama (`git push origin mejora/MiMejora`)
5. Abre un Pull Request

## 📝 Licencia

Proyecto educativo de código abierto.

## 🆘 Solución de Problemas

### Error: "No space left on device"
- Limpia imágenes Docker antiguas: `docker system prune -a`

### Error: "Task failed to start"
- Revisa logs en CloudWatch
- Verifica que la imagen existe en ECR
- Confirma credenciales de BD

### WordPress no carga
- Verifica Security Groups
- Revisa health checks del ALB
- Confirma que ECS tiene tareas running

## 📚 Recursos de Aprendizaje

- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS ECS Best Practices](https://docs.aws.amazon.com/AmazonECS/latest/bestpracticesguide/)
- [Docker Documentation](https://docs.docker.com/)
- [WordPress on AWS](https://aws.amazon.com/blogs/architecture/wordpress-best-practices-on-aws/)
