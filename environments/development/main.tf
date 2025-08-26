terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

module "wordpress_infrastructure" {
  source = "../../"

  environment = "development"
  aws_region  = var.aws_region

  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones

  db_instance_class = var.db_instance_class
  db_name           = var.db_name
  db_username       = var.db_username
  db_password       = var.db_password

  wordpress_image   = var.wordpress_image
  ecs_desired_count = var.ecs_desired_count
  ecs_cpu           = var.ecs_cpu
  ecs_memory        = var.ecs_memory
}