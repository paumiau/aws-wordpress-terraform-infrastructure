aws_region = "us-east-1"
vpc_cidr   = "10.1.0.0/16"
availability_zones = ["us-east-1a", "us-east-1b"]

db_instance_class = "db.t3.small"
db_name          = "wordpress_prod"
db_username      = "admin"

wordpress_image   = "763273873669.dkr.ecr.us-east-1.amazonaws.com/paumiau_wp:latest"
ecs_desired_count = 3
ecs_cpu          = 512
ecs_memory       = 1024