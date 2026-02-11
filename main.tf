# Networking Module
module "vpc" {
  source        = "./modules/vpc"
  vpc_cidr      = var.vpc_cidr
  public_cidrs  = var.public_subnets
  private_cidrs = var.private_subnets
  azs           = var.availability_zones
}

# Security Groups Module
module "security_groups" {
  source   = "./modules/security_groups"
  vpc_id   = module.vpc.vpc_id
  admin_ip = var.admin_ip
}

# RDS Database Module
module "rds" {
  source             = "./modules/rds"
  private_subnet_ids = module.vpc.private_subnet_ids
  rds_sg_id          = module.security_groups.rds_sg_id
  db_password        = var.db_password
}

# Application Load Balancer Module
module "alb" {
  source            = "./modules/alb"
  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
  alb_sg_id         = module.security_groups.alb_sg_id
}

# EC2 Instances Module
module "ec2" {
  source            = "./modules/ec2"
  public_subnet_ids = module.vpc.public_subnet_ids
  ec2_sg_id         = module.security_groups.ec2_sg_id
  target_group_arn  = module.alb.target_group_arn
  key_name          = aws_key_pair.generated_key.key_name
  db_name           = module.rds.db_name
  db_username       = module.rds.db_username
  db_host           = module.rds.db_host
  db_port           = module.rds.db_port
  db_password       = var.db_password
}

# Generate a secure Private Key
resource "tls_private_key" "main" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Register the Public Key with AWS
resource "aws_key_pair" "generated_key" {
  key_name   = "project-key"
  public_key = tls_private_key.main.public_key_openssh
}

# Save the Private Key to your local folder
resource "local_file" "private_key" {
  content         = tls_private_key.main.private_key_pem
  filename        = "${path.module}/project-key.pem"
  file_permission = "0400" # Sets correct read-only permissions automatically
}
