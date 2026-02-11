output "alb_dns_name" {
  description = "The DNS name of the Application Load Balancer"
  # The try() function handles the case where the list [0] is empty
  value = try(aws_lb.application_lb[0].dns_name, "")
}

output "target_group_arn" {
  description = "The ARN of the Application Load Balancer target group"
  value       = one(aws_lb_target_group.app_tg[*].arn)
}

output "enable_alb" {
  description = "Indicates if the ALB is enabled"
  value       = var.enable_alb
}
