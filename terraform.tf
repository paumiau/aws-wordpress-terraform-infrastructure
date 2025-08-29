# =============================================================================
# CONFIGURACIÓN DE TERRAFORM Y PROVEEDORES
# =============================================================================
# Este archivo centraliza la configuración de versiones de Terraform y 
# proveedores requeridos, evitando duplicación en otros archivos.
# =============================================================================

terraform {
  # Versión mínima de Terraform requerida
  required_version = ">= 1.0"
  
  # Proveedores requeridos y sus versiones
  required_providers {
    aws = {
      source  = "hashicorp/aws"  # Proveedor oficial de AWS de HashiCorp
      version = "~> 5.0"          # Versión 5.x (permite actualizaciones menores)
    }
  }
  
  # Backend configuration (descomentar y configurar para usar estado remoto)
  # backend "s3" {
  #   bucket         = "terraform-state-bucket"
  #   key            = "wordpress/terraform.tfstate"
  #   region         = "us-east-1"
  #   encrypt        = true
  #   dynamodb_table = "terraform-state-lock"
  # }
}
