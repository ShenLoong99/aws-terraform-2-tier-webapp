resource "aws_lb" "application_lb" {
  count                      = var.enable_alb ? 1 : 0 # Create 1 if true, 0 if false
  name                       = var.aws_lb_name
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [var.alb_sg_id]
  subnets                    = var.public_subnet_ids
  drop_invalid_header_fields = true

  # Enable Cross-Zone Load Balancing
  enable_cross_zone_load_balancing = true

  access_logs {
    bucket  = aws_s3_bucket.alb_logs[0].id
    enabled = true
  }

  tags = {
    Name = var.aws_lb_name
  }
}

resource "aws_lb_target_group" "app_tg" {
  count       = var.enable_alb ? 1 : 0 # Create 1 if true, 0 if false
  name_prefix = "app-tg"               # Max 6 characters for prefix
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
  # checkov:skip=CKV_AWS_103:TLS policy is not applicable to HTTP listeners.
  count             = var.enable_alb ? 1 : 0 # --- TOGGLE ---
  load_balancer_arn = aws_lb.application_lb[0].arn
  port              = "80"
  protocol          = "HTTP"

  # This line only belongs on port 443 listeners
  # ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg[0].arn
  }
}

# The S3 Bucket
resource "aws_s3_bucket" "alb_logs" {
  count         = var.enable_alb ? 1 : 0 # Create only if ALB is enabled
  bucket        = "my-alb-debug-logs-${random_id.suffix.hex}"
  force_destroy = true
}

# Block Public Access
resource "aws_s3_bucket_public_access_block" "alb_logs_public_access_block" {
  bucket = aws_s3_bucket.alb_logs[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# enable versioning
resource "aws_s3_bucket_versioning" "alb_logs_versioning" {
  bucket = aws_s3_bucket.alb_logs[0].id
  versioning_configuration {
    status = "Enabled"
  }
}

# Add the REQUIRED Policy for ap-southeast-1
resource "aws_s3_bucket_policy" "alb_log_policy" {
  bucket = aws_s3_bucket.alb_logs[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          # This ID is specific to ap-southeast-1 (Singapore)
          AWS = "arn:aws:iam::114774131450:root"
        }
        Action = "s3:PutObject"
        # Grant access to the AWSLogs path within the bucket
        Resource = "${aws_s3_bucket.alb_logs[0].arn}/*"
      }
    ]
  })
}

resource "random_id" "suffix" {
  byte_length = 4
}

resource "aws_s3_bucket_lifecycle_configuration" "log_lifecycle" {
  bucket = aws_s3_bucket.alb_logs[0].id

  rule {
    id     = "delete-old-logs"
    status = "Enabled"

    # Abort failed uploads after 7 days to save money
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }

    # The filter block must contain either 'prefix' or 'and'
    filter {}

    expiration {
      days = 14 # Automatically deletes logs older than 14 days
    }
  }
}

# Enable Server-Side Encryption (SSE-S3)
resource "aws_s3_bucket_server_side_encryption_configuration" "alb_logs_encryption" {
  bucket = aws_s3_bucket.alb_logs[0].id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256" # Required for ALB compatibility
    }
  }
}
