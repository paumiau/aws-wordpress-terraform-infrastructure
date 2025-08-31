output "repo_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecr_repository.main.name
}
