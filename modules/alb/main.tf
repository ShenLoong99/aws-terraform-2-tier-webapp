# Application Load Balancer
resource "aws_lb" "application_lb" {
  name                       = "webapp-2-tier-alb"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [var.alb_sg_id]
  subnets                    = var.public_subnet_ids
  drop_invalid_header_fields = true
  depends_on                 = [var.alb_log_policy_id]

  access_logs {
    bucket  = var.alb_logs_id
    enabled = true
  }

  tags = {
    Name = "webapp-2-tier-alb"
  }
}

# Target Group for the ALB to route traffic to EC2 instances
resource "aws_lb_target_group" "app_tg" {
  name_prefix = "app-tg" # Max 6 characters for prefix
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = var.vpc_id

  health_check {
    path                = "/"
    port                = "3000" # ALB checks health on this port too
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Listener for HTTP (port 80)
resource "aws_lb_listener" "http" {
  # checkov:skip=CKV_AWS_103:TLS policy is not applicable to HTTP listeners.
  load_balancer_arn = aws_lb.application_lb.arn
  port              = "80"
  protocol          = "HTTP"

  # This line only belongs on port 443 listeners
  # ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}
