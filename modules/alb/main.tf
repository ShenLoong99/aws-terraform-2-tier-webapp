resource "aws_lb" "application_lb" {
  name               = var.aws_lb_name
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_sg_id]
  subnets            = var.public_subnet_ids

  # Enable Cross-Zone Load Balancing
  enable_cross_zone_load_balancing = true

  tags = {
    Name = var.aws_lb_name
  }
}

resource "aws_lb_target_group" "app_tg" {
  # Change 'name' to 'name_prefix'
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

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.application_lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}