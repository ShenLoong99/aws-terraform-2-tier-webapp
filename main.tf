provider "aws" {
  region = var.region

  default_tags {
    tags = local.common_tags
  }
}

locals {
  common_tags = {
    Project     = "Project-5-Two-Tier-WebApp"
    Environment = "Development"
    Owner       = "ShenLoong"
    ManagedBy   = "Terraform"
    CostCenter  = "Cloud-Learning"
  }
}

# Fetch your current public IP address
data "http" "my_ip" {
  url = "https://ipv4.icanhazip.com"
}

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
  source = "./modules/security_groups"
  vpc_id = module.vpc.vpc_id
  # Clean the response body with chomp() to remove hidden newlines
  admin_ip = chomp(data.http.my_ip.response_body)
}

# RDS Database Module
module "rds" {
  source             = "./modules/rds"
  private_subnet_ids = module.vpc.private_subnet_ids
  rds_sg_id          = module.security_groups.rds_sg_id
  db_password        = var.db_password
  db_instance_class  = "db.${var.instance_type}"
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
  source = "./modules/ec2"
  # This is where the variables get their values!
  public_subnet_ids = module.vpc.public_subnet_ids
  ec2_sg_id         = module.security_groups.ec2_sg_id
  target_group_arn  = module.alb.target_group_arn
  instance_type     = var.instance_type
  key_name          = aws_key_pair.generated_key.key_name
}

resource "aws_cloudwatch_log_group" "app_logs" {
  name              = "/aws/ec2/webapp-2-tier-project"
  retention_in_days = 7 # Saves cost: logs deleted after 7 days
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