output "alb_dns_name" {
  description = "The DNS name of the Application Load Balancer"
  value       = aws_lb.application_lb.dns_name
}

output "target_group_arn" {
  description = "The ARN of the Application Load Balancer target group"
  value       = aws_lb_target_group.app_tg.arn
}
