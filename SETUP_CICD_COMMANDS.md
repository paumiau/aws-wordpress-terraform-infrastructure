# Comandos de Configuración CI/CD

Este archivo contiene todos los comandos necesarios para configurar el pipeline CI/CD con GitHub Actions y AWS.

## 📋 Pre-requisitos

- AWS CLI configurado
- GitHub CLI (`gh`) instalado
- Terraform aplicado (infraestructura creada)
- Permisos de administrador en el repositorio de GitHub

## 1️⃣ Crear Repositorios ECR en AWS

Ejecuta estos comandos para crear los repositorios ECR separados para desarrollo y producción:

```bash
# Crear repositorio ECR para desarrollo
aws ecr create-repository \
  --repository-name wordpress-dev \
  --region us-east-1 \
  --image-scanning-configuration scanOnPush=true \
  --image-tag-mutability MUTABLE

# Crear repositorio ECR para producción
aws ecr create-repository \
  --repository-name wordpress-prod \
  --region us-east-1 \
  --image-scanning-configuration scanOnPush=true \
  --image-tag-mutability IMMUTABLE

# Obtener las URIs de los repositorios (guarda estos valores)
aws ecr describe-repositories --repository-names wordpress-dev wordpress-prod \
  --region us-east-1 \
  --query 'repositories[*].[repositoryName,repositoryUri]' \
  --output table
```

## 2️⃣ Configurar Políticas de Ciclo de Vida en ECR

```bash
# Política para desarrollo (mantener últimas 10 imágenes)
cat > ecr-lifecycle-dev.json << 'EOF'
{
  "rules": [
    {
      "rulePriority": 1,
      "description": "Keep last 10 images",
      "selection": {
        "tagStatus": "any",
        "countType": "imageCountMoreThan",
        "countNumber": 10
      },
      "action": {
        "type": "expire"
      }
    }
  ]
}
EOF

aws ecr put-lifecycle-policy \
  --repository-name wordpress-dev \
  --lifecycle-policy-text file://ecr-lifecycle-dev.json \
  --region us-east-1

# Política para producción (mantener últimas 30 imágenes)
cat > ecr-lifecycle-prod.json << 'EOF'
{
  "rules": [
    {
      "rulePriority": 1,
      "description": "Keep last 30 production images",
      "selection": {
        "tagStatus": "tagged",
        "tagPrefixList": ["v"],
        "countType": "imageCountMoreThan",
        "countNumber": 30
      },
      "action": {
        "type": "expire"
      }
    }
  ]
}
EOF

aws ecr put-lifecycle-policy \
  --repository-name wordpress-prod \
  --lifecycle-policy-text file://ecr-lifecycle-prod.json \
  --region us-east-1

# Limpiar archivos temporales
rm ecr-lifecycle-dev.json ecr-lifecycle-prod.json
```

## 3️⃣ Crear Usuario IAM para GitHub Actions

```bash
# Crear usuario IAM
aws iam create-user --user-name github-actions-wordpress

# Crear política personalizada
cat > github-actions-policy.json << 'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:PutImage",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload",
        "ecr:DescribeRepositories",
        "ecr:ListImages"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ecs:UpdateService",
        "ecs:DescribeServices",
        "ecs:DescribeTaskDefinition",
        "ecs:RegisterTaskDefinition",
        "ecs:ListTaskDefinitions",
        "ecs:DescribeTasks"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "iam:PassRole"
      ],
      "Resource": "arn:aws:iam::*:role/ecsTaskExecutionRole"
    }
  ]
}
EOF

# Crear la política
aws iam create-policy \
  --policy-name GitHubActionsWordPressPolicy \
  --policy-document file://github-actions-policy.json \
  --description "Policy for GitHub Actions to deploy WordPress to ECS"

# Obtener el ARN de la política (guarda este valor)
POLICY_ARN=$(aws iam list-policies --query "Policies[?PolicyName=='GitHubActionsWordPressPolicy'].Arn" --output text)
echo "Policy ARN: $POLICY_ARN"

# Adjuntar la política al usuario
aws iam attach-user-policy \
  --user-name github-actions-wordpress \
  --policy-arn $POLICY_ARN

# Crear access key para el usuario
aws iam create-access-key --user-name github-actions-wordpress > github-actions-credentials.json

# Mostrar las credenciales (GUÁRDALAS DE FORMA SEGURA)
cat github-actions-credentials.json

# Limpiar archivo temporal
rm github-actions-policy.json
```

## 4️⃣ Configurar Secrets en GitHub

Usa el GitHub CLI para configurar los secrets necesarios:

```bash
# Navegar al directorio del repositorio
cd /home/user/Programacion/Devops/Terraform/aws_wp

# Extraer las credenciales del archivo JSON
ACCESS_KEY_ID=$(cat github-actions-credentials.json | jq -r '.AccessKey.AccessKeyId')
SECRET_ACCESS_KEY=$(cat github-actions-credentials.json | jq -r '.AccessKey.SecretAccessKey')

# Configurar los secrets en GitHub
gh secret set AWS_ACCESS_KEY_ID --body "$ACCESS_KEY_ID"
gh secret set AWS_SECRET_ACCESS_KEY --body "$SECRET_ACCESS_KEY"

# Eliminar el archivo de credenciales por seguridad
rm github-actions-credentials.json

# Verificar que los secrets se crearon
gh secret list
```

## 5️⃣ Configurar Environments en GitHub

```bash
# Crear environment de desarrollo
gh api --method PUT \
  -H "Accept: application/vnd.github+json" \
  /repos/{owner}/{repo}/environments/development \
  -f wait_timer=0 \
  -F reviewers='[]' \
  -F deployment_branch_policy='{"protected_branches":false,"custom_branch_policies":true}'

# Crear environment de producción con aprobación
gh api --method PUT \
  -H "Accept: application/vnd.github+json" \
  /repos/{owner}/{repo}/environments/production \
  -f wait_timer=0 \
  -F reviewers='[{"type":"User","id":YOUR_USER_ID}]' \
  -F deployment_branch_policy='{"protected_branches":false,"custom_branch_policies":true}'

# Crear environment para aprobación de producción
gh api --method PUT \
  -H "Accept: application/vnd.github+json" \
  /repos/{owner}/{repo}/environments/production-approval \
  -f wait_timer=0 \
  -F reviewers='[{"type":"User","id":YOUR_USER_ID}]'
```

**Nota**: Reemplaza `{owner}`, `{repo}` y `YOUR_USER_ID` con los valores correctos.

Para obtener tu USER_ID:
```bash
gh api user --jq .id
```

## 6️⃣ Crear Branch de Desarrollo

```bash
# Crear y cambiar a branch develop
git checkout -b develop
git push -u origin develop
```

## 7️⃣ Configurar Branch Protection (Opcional pero Recomendado)

```bash
# Proteger main branch
gh api --method PUT \
  -H "Accept: application/vnd.github+json" \
  /repos/{owner}/{repo}/branches/main/protection \
  -F required_status_checks='{"strict":true,"contexts":["test","security-scan"]}' \
  -F enforce_admins=false \
  -F required_pull_request_reviews='{"required_approving_review_count":1}' \
  -F restrictions=null

# Proteger develop branch
gh api --method PUT \
  -H "Accept: application/vnd.github+json" \
  /repos/{owner}/{repo}/branches/develop/protection \
  -F required_status_checks='{"strict":true,"contexts":["test"]}' \
  -F enforce_admins=false \
  -F required_pull_request_reviews=null \
  -F restrictions=null
```

## 8️⃣ Actualizar Servicios ECS (Si es necesario)

Si los servicios ECS no existen o necesitas crearlos/actualizarlos:

```bash
# Para desarrollo
aws ecs update-service \
  --cluster development-cluster \
  --service wordpress-service \
  --desired-count 1 \
  --region us-east-1

# Para producción (cuando tengas el cluster de producción)
# aws ecs update-service \
#   --cluster production-cluster \
#   --service wordpress-service \
#   --desired-count 2 \
#   --region us-east-1
```

## 9️⃣ Primera Imagen Base (Opcional)

Para tener una imagen inicial en ECR:

```bash
# Login a ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 763273873669.dkr.ecr.us-east-1.amazonaws.com

# Build y push inicial para desarrollo
cd app/
docker build -t wordpress-dev .
docker tag wordpress-dev:latest 763273873669.dkr.ecr.us-east-1.amazonaws.com/wordpress-dev:initial
docker push 763273873669.dkr.ecr.us-east-1.amazonaws.com/wordpress-dev:initial
cd ..
```

## 🔍 Verificación

Para verificar que todo está configurado correctamente:

```bash
# Verificar repositorios ECR
aws ecr describe-repositories --region us-east-1

# Verificar secrets en GitHub
gh secret list

# Verificar environments
gh api /repos/{owner}/{repo}/environments

# Verificar workflows
gh workflow list

# Ver estado de los servicios ECS
aws ecs describe-services \
  --cluster development-cluster \
  --services wordpress-service \
  --region us-east-1
```

## 🚀 Trigger del Pipeline

Una vez configurado todo:

### Para Development:
```bash
# Hacer un cambio en la app
echo "# Test CI/CD" >> app/README.md
git add app/README.md
git commit -m "test: trigger CI/CD pipeline"
git push origin develop
```

### Para Production:
```bash
# Crear un tag de versión
git tag v1.0.0
git push origin v1.0.0
```

## ⚠️ Notas Importantes

1. **Guarda las credenciales de forma segura**: Las access keys del usuario IAM son sensibles
2. **Revisa los permisos IAM**: Ajusta según tus necesidades de seguridad
3. **Configura alertas**: Considera configurar CloudWatch alarms para los servicios
4. **Monitoreo**: Revisa regularmente los logs de GitHub Actions y CloudWatch
5. **Costos**: Los repositorios ECR y las ejecuciones de GitHub Actions tienen costos asociados

## 🔧 Solución de Problemas

Si encuentras errores:

1. **Error de permisos AWS**: Verifica que el usuario IAM tenga los permisos correctos
2. **Error de ECR**: Asegúrate de que los repositorios existan y sean accesibles
3. **Error de ECS**: Verifica que el cluster y servicio existan
4. **Error de GitHub Actions**: Revisa los logs en la pestaña Actions del repositorio

## 📚 Referencias

- [GitHub CLI Documentation](https://cli.github.com/manual/)
- [AWS CLI Documentation](https://docs.aws.amazon.com/cli/)
- [GitHub Actions Secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
- [AWS ECR Documentation](https://docs.aws.amazon.com/ecr/)
- [AWS ECS Documentation](https://docs.aws.amazon.com/ecs/)