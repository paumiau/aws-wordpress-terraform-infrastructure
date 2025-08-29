variable "environment" {
  description = "Environment name"
  type        = string

  validation {
    condition     = contains(["development", "production", "staging"], var.environment)
    error_message = "Environment must be development, production, or staging."
  }
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid IPv4 CIDR block."
  }
}

variable "availability_zones" {
  description = "List of availability zones (optional - will use available zones if not specified)"
  type        = list(string)
  default     = [] # Vacío por defecto, se detectarán automáticamente
}
