# Capture the output from the module blocks
# ALB Outputs
output "alb_dns_name" {
  description = "The DNS name of the load balancer"
  value       = module.alb.alb_dns_name
}

output "app_url" {
  description = "The clickable URL for the application"
  value       = "http://${module.alb.alb_dns_name}"
}

output "alb_target_group_arn" {
  value = module.alb.target_group_arn
}

# RDS Outputs
output "rds_endpoint" {
  description = "The connection endpoint for the RDS instance"
  value       = module.rds.db_instance_endpoint
}

# EC2 Outputs
output "ec2_public_ips" {
  description = "Public IP addresses of the EC2 instances"
  value       = module.ec2.public_ips
}

output "ec2_instance_ids" {
  description = "IDs from the EC2 module"
  value       = module.ec2.instance_ids
}

# Security Groups Outputs
output "alb_sg_id" {
  description = "Security Group ID of the ALB"
  value       = module.security_groups.alb_sg_id
}

output "ec2_sg_id" {
  description = "Security Group ID of the EC2 instances"
  value       = module.security_groups.ec2_sg_id
}

output "rds_sg_id" {
  description = "Security Group ID of the RDS instance"
  value       = module.security_groups.rds_sg_id
}

# VPC Outputs
output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.vpc.private_subnet_ids
}

output "aws_region" {
  description = "The AWS region in use"
  value       = var.aws_region
}

output "selected_ami_name" {
  description = "The name of the selected Amazon Linux 2 AMI"
  value       = module.ec2.selected_ami_name
}

output "selected_ami_id" {
  description = "The ID of the selected Amazon Linux 2 AMI"
  value       = module.ec2.selected_ami_id
}
