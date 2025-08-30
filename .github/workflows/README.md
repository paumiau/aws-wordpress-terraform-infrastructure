# GitHub Actions CI/CD Workflows

Este directorio contiene los workflows de CI/CD para el proyecto WordPress en AWS.

## 📋 Estructura de Workflows

### 1. **docker-build.yml** (Workflow Reutilizable)
- **Propósito**: Construir y publicar imágenes Docker a ECR
- **Características**:
  - Build con cache para optimización
  - Escaneo de vulnerabilidades con Trivy
  - Análisis de Dockerfile con Hadolint
  - Generación automática de tags según ambiente
- **Uso**: Llamado por otros workflows, no se ejecuta directamente

### 2. **deploy-development.yml**
- **Trigger**: Push a `develop` o `main`
- **Ambiente**: Development
- **Características**:
  - Deploy automático sin aprobación
  - Tests de integración básicos
  - Health checks post-deployment
  - Smoke tests

### 3. **deploy-production.yml**
- **Trigger**: Tags semver (v1.0.0) o manual
- **Ambiente**: Production
- **Características**:
  - Requiere aprobación manual
  - Tests completos de integración
  - Backup antes del deployment
  - Rollback automático en caso de fallo
  - Monitoreo post-deployment

### 4. **security-scan.yml**
- **Trigger**: PRs, schedule semanal, manual
- **Características**:
  - Escaneo de secretos (Gitleaks)
  - Análisis SAST (Semgrep)
  - Escaneo de IaC (Checkov, Terrascan)
  - Análisis de contenedores (Trivy, Dockle)
  - Verificación de compliance

## 🏷️ Estrategia de Versionado

### Development
- **Formato**: `dev-{sha}`, `dev-latest`, `dev-YYYYMMDD-HHmmss`
- **Ejemplo**: `dev-abc123`, `dev-latest`

### Production
- **Formato**: Semver tags
- **Ejemplos**:
  - `v1.0.0` - Release estable
  - `v1.0.0-rc1` - Release candidate
  - `latest` - Última versión estable

## 🔐 Secrets Requeridos

Los siguientes secrets deben estar configurados en GitHub:

- `AWS_ACCESS_KEY_ID`: ID de acceso AWS
- `AWS_SECRET_ACCESS_KEY`: Clave secreta AWS
- `SNYK_TOKEN`: (Opcional) Token de Snyk para escaneo adicional
- `FOSSA_API_KEY`: (Opcional) Para análisis de licencias

## 🚀 Flujo de Deployment

### Development (Continuous Deployment)
```
Push a develop/main → Tests → Build → Push a ECR → Deploy a ECS → Smoke Tests
```

### Production (Continuous Delivery)
```
Tag v1.0.0 → Aprobación → Tests Completos → Build → Backup → Deploy → Verificación → Rollback si falla
```

## 🧪 Tests Incluidos

### Tests de Build
- Validación de sintaxis PHP
- Build de Docker sin errores
- Verificación de archivos críticos

### Tests de Integración
- Inicio correcto del contenedor
- Conexión con base de datos
- Health checks de WordPress

### Tests de Seguridad
- Escaneo de vulnerabilidades (Trivy)
- Análisis de código estático (Semgrep)
- Detección de secretos (Gitleaks)
- Mejores prácticas de Docker (Hadolint, Dockle)

### Tests Post-Deployment
- Disponibilidad de la aplicación
- Tiempo de respuesta
- Verificación de endpoints críticos

## 🔧 Mejores Prácticas Implementadas

1. **Separación de Ambientes**: Workflows distintos para dev y prod
2. **Aprobación Manual**: Requerida para producción
3. **Versionado Semántico**: Tags claros y consistentes
4. **Rollback Automático**: En caso de fallo en producción
5. **Cache de Docker**: Para builds más rápidos
6. **Escaneo de Seguridad**: En múltiples niveles
7. **Tests Comprehensivos**: Unitarios, integración y smoke tests
8. **Monitoreo**: Health checks y performance tests
9. **Backup**: Antes de deployments a producción
10. **Documentación**: Workflows auto-documentados

## 📊 Monitoreo y Alertas

Los workflows generan:
- Summaries en GitHub Actions
- Reportes SARIF en la pestaña Security
- Logs detallados de cada paso
- Métricas de performance

## 🛠️ Mantenimiento

### Actualizar versiones de Actions
Revisar periódicamente y actualizar las versiones de las GitHub Actions utilizadas.

### Revisar políticas de seguridad
Los escaneos de seguridad deben revisarse semanalmente.

### Optimizar tiempos de build
Monitorear y optimizar el uso de cache y paralelización.

## 📚 Referencias

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [AWS ECS Deploy Action](https://github.com/aws-actions/amazon-ecs-deploy-task-definition)
- [Docker Build Action](https://github.com/docker/build-push-action)
- [Trivy Scanner](https://github.com/aquasecurity/trivy)
- [Semgrep](https://semgrep.dev/)
- [Checkov](https://www.checkov.io/)