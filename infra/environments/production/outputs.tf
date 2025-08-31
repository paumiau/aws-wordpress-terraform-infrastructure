# Outputs del entorno de producción
output "wordpress_url" {
  description = "WordPress application URL"
  value       = module.wordpress_infrastructure.wordpress_url
}

output "load_balancer_dns" {
  description = "DNS name of the load balancer"
  value       = module.wordpress_infrastructure.load_balancer_dns
}

output "rds_endpoint" {
  description = "RDS instance endpoint"
  value       = module.wordpress_infrastructure.rds_endpoint
  sensitive   = true
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = module.wordpress_infrastructure.ecs_cluster_name
}

output "ecs_service_name" {
  description = "Name of the ECS service"
  value       = module.wordpress_infrastructure.ecs_service_name
}

output "ecr_repository_url" {
  description = "URL of the ECR repository"
  value       = module.wordpress_infrastructure.ecr_repository_url
}

output "deployment_commands" {
  description = "Useful commands for deployment"
  value       = module.wordpress_infrastructure.deployment_commands
}
