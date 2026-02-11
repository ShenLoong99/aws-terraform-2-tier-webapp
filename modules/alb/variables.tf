variable "vpc_id" {
  description = "The VPC ID where the ALB will be deployed"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs"
  type        = list(string)
}

variable "alb_sg_id" {
  description = "The security group ID for the ALB"
  type        = string
}

variable "aws_lb_name" {
  description = "The name of the Application Load Balancer"
  type        = string
  default     = "webapp-2-tier-alb"
}
