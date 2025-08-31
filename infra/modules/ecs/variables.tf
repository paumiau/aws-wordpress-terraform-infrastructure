# Variables básicas
variable "environment" {
  description = "Environment name (development/staging/production)"
  type        = string
}

# Variables de red
variable "private_subnet_ids" {
  description = "Private subnet IDs where containers will run"
  type        = list(string)
}

variable "security_group_ids" {
  description = "Security group IDs for containers"
  type        = list(string)
}

# Variables de integración
variable "target_group_arn" {
  description = "ALB target group ARN"
  type        = string
}

variable "repository_url" {
  description = "ECR repository URL"
  type        = string
}

# Variables IAM
variable "task_execution_role" {
  description = "IAM role ARN for ECS task execution"
  type        = string
}

variable "task_role" {
  description = "IAM role ARN for running tasks"
  type        = string
}

# Variables de base de datos
variable "db_host" {
  description = "Database endpoint"
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

# Variables de configuración de contenedores
variable "desired_count" {
  description = "Number of containers to run"
  type        = number
  default     = 2
}

variable "cpu" {
  description = "CPU units (256, 512, 1024, 2048, 4096)"
  type        = number
  default     = 256
}

variable "memory" {
  description = "Memory in MB"
  type        = number
  default     = 512
}

variable "image_tag" {
  description = "Docker image tag"
  type        = string
  default     = "latest"
}
