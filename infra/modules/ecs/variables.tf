variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs"
  type        = list(string)
}

variable "security_group_ids" {
  description = "Security group IDs"
  type        = list(string)
}

variable "target_group_arn" {
  description = "Target group ARN"
  type        = string
}

variable "task_execution_role" {
  description = "ECS task execution role ARN"
  type        = string
}

variable "task_role" {
  description = "ECS task role ARN"
  type        = string
}

variable "wordpress_image" {
  description = "WordPress Docker image"
  type        = string
}

variable "db_host" {
  description = "Database host"
  type        = string
}

variable "db_name" {
  description = "Database name"
  type        = string
}

variable "db_username" {
  description = "Database username"
  type        = string
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}

variable "desired_count" {
  description = "Desired number of ECS tasks"
  type        = number
}

variable "cpu" {
  description = "CPU units for ECS tasks"
  type        = number
}

variable "memory" {
  description = "Memory for ECS tasks"
  type        = number
}

variable "repo_name" {
  description = "Name of the AWS ECR image repository"
  type        = string
}