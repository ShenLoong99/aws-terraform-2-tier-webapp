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

variable "alb_logs_id" {
  description = "The ID of the S3 bucket for ALB access logs"
  type        = string
}

variable "alb_log_policy_id" {
  description = "The S3 bucket policy for ALB access logs"
  type        = string
}
