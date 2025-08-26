output "wordpress_url" {
  description = "WordPress application URL"
  value       = "http://${module.wordpress_infrastructure.load_balancer_dns}"
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.wordpress_infrastructure.vpc_id
}

output "rds_endpoint" {
  description = "RDS instance endpoint"
  value       = module.wordpress_infrastructure.rds_endpoint
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = module.wordpress_infrastructure.ecs_cluster_name
}