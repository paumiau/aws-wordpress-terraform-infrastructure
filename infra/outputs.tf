# =============================================================================
# Outputs principales
# =============================================================================

# Acceso a WordPress
output "wordpress_url" {
  description = "URL to access WordPress"
  value       = "http://${module.alb.dns_name}"
}

output "load_balancer_dns" {
  description = "DNS name of the load balancer"
  value       = module.alb.dns_name
}

# Información de la base de datos
output "rds_endpoint" {
  description = "RDS instance endpoint"
  value       = module.rds.db_endpoint
  sensitive   = true
}

# Información de ECS
output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = module.ecs.cluster_name
}

output "ecs_service_name" {
  description = "Name of the ECS service"
  value       = module.ecs.service_name
}

# Información de ECR
output "ecr_repository_url" {
  description = "URL of the ECR repository"
  value       = module.ecr.repository_url
}

output "ecr_repository_name" {
  description = "Name of the ECR repository"
  value       = module.ecr.repository_name
}

# Comandos útiles para el despliegue
output "deployment_commands" {
  description = "Useful commands for deployment"
  value = <<-EOT
    
    ========== Docker Commands ==========
    # 1. Login to ECR:
    aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${module.ecr.repository_url}
    
    # 2. Build image:
    docker build -t wordpress ./app
    
    # 3. Tag image:
    docker tag wordpress:latest ${module.ecr.repository_url}:latest
    
    # 4. Push image:
    docker push ${module.ecr.repository_url}:latest
    
    ========== ECS Commands ==========
    # Force new deployment:
    aws ecs update-service --cluster ${module.ecs.cluster_name} --service ${module.ecs.service_name} --force-new-deployment
    
    # View service status:
    aws ecs describe-services --cluster ${module.ecs.cluster_name} --services ${module.ecs.service_name}
    
    # View logs:
    aws logs tail /ecs/${var.environment}-wordpress --follow
  EOT
}
