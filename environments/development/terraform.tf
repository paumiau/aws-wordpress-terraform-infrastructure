# =============================================================================
# BACKEND S3 - DEVELOPMENT
# =============================================================================
# Este archivo configura dónde Terraform almacenará el estado de este entorno
# =============================================================================

terraform {
  backend "s3" {
    # Reemplaza estos valores con los tuyos
    bucket = "terraform-state-wordpress-763273873669-us-east-1"  # Tu bucket
    key    = "wordpress/development/terraform.tfstate"            # Path único
    region = "us-east-1"                                         # Tu región
    
    # habilitamos el lock nativo de S3 para evitar corrupciones en el state file
    use_lockfile = true

    # Seguridad
    encrypt = true                    # Encriptar el state file
    
  }
}