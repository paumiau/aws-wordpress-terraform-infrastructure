aws_region         = "us-east-1"
vpc_cidr           = "10.0.0.0/16"
availability_zones = ["us-east-1a", "us-east-1b"]

db_instance_class = "db.t3.micro"
db_name           = "wordpress_dev"
db_username       = "admin"

wordpress_image   = "763273873669.dkr.ecr.us-east-1.amazonaws.com/paumiau_wp:latest"
ecs_desired_count = 1
ecs_cpu           = 256
ecs_memory        = 512