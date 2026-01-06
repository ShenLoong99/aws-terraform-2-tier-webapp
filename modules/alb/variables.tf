variable "vpc_id" {
  type = string
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "alb_sg_id" {
  type = string
}

variable "aws_lb_name" {
  type    = string
  default = "webapp-2-tier-alb"
}