# Fetch the latest Amazon Linux 2 AMI (arm64)
data "aws_ami" "latest_amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023*-arm64"] # Added -arm64 suffix
  }

  filter {
    name   = "architecture"
    values = ["arm64"] # Explicitly filter for ARM
  }
}

# find all running instances that belong to ASG
data "aws_instances" "asg_instances" {
  instance_state_names = ["running"]

  filter {
    name   = "tag:Name"
    values = ["ASG-Web-Server"] # Matches the tag in your launch template
  }

  # Ensures this only runs after the ASG has started creating instances
  depends_on = [aws_autoscaling_group.app_asg]
}

# Launch Template and Auto Scaling Group using the Golden AMI
resource "aws_launch_template" "app_lt" {
  name_prefix   = "webapp-launch-template-"
  image_id      = data.aws_ami.latest_amazon_linux.id
  instance_type = "t4g.nano"
  key_name      = var.key_name

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required" # Forces the use of IMDSv2
    http_put_response_hop_limit = 1
  }

  # Security Groups are now handled inside network_interfaces for templates
  # checkov:skip=CKV_AWS_88:Public IP is enabled to avoid NAT Gateway costs ($32/mo). Access is restricted via Security Group to the Admin's specific IP.
  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [var.ec2_sg_id]
  }

  # Use Spot Instances for ~70-90% savings
  instance_market_options {
    market_type = "spot"
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }

  # Your existing user_data script
  user_data = base64encode(templatefile("${path.module}/scripts/user_data.tftpl", {
    index_js_content = file("${path.module}/scripts/index.js")
    db_host          = var.db_host
    db_user          = var.db_username
    db_pass          = var.db_password
    db_name          = var.db_name
    db_port          = var.db_port
  }))

  lifecycle {
    create_before_destroy = true
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "ASG-Web-Server"
    }
  }
}

# Auto Scaling Group to manage EC2 Instances
resource "aws_autoscaling_group" "app_asg" {
  name                = "webapp-asg"
  desired_capacity    = 1 # Absolute minimum for cost saving
  max_size            = 2 # Allow small burst if needed
  min_size            = 1
  vpc_zone_identifier = var.public_subnet_ids  # Spans multiple AZs for reliability
  target_group_arns   = [var.target_group_arn] # Attach to the ALB Target Group

  launch_template {
    id      = aws_launch_template.app_lt.id
    version = aws_launch_template.app_lt.latest_version
  }

  health_check_type         = "ELB"
  health_check_grace_period = 300

  # When Launch Template changes, replace all old instances with new ones
  instance_refresh {
    strategy = "Rolling"
    preferences {
      # Keep at least 1 instance running at all times (50% of 2)
      min_healthy_percentage = 50
    }
  }

  # Ensures replacement instances are created before old ones are deleted
  lifecycle {
    create_before_destroy = true
  }

  # Tag for the ASG itself + all launched Instances
  tag {
    key                 = "Name"
    value               = "WebApp-Instance"
    propagate_at_launch = true # CRITICAL: This makes the tag show up on EC2
  }
  tag {
    key                 = "Environment"
    value               = "Development"
    propagate_at_launch = true
  }
  tag {
    key                 = "Project"
    value               = "To Do List App"
    propagate_at_launch = true
  }
}

# Create the IAM Role
resource "aws_iam_role" "ec2_cloudwatch_role" {
  name = "ec2-cloudwatch-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

# Attach the CloudWatch Agent Policy
resource "aws_iam_role_policy_attachment" "cw_policy" {
  role       = aws_iam_role.ec2_cloudwatch_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Attach the SSM Policy so the agent can fetch its config
resource "aws_iam_role_policy_attachment" "ssm_policy" {
  role       = aws_iam_role.ec2_cloudwatch_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Create the Instance Profile (This is what the EC2 actually uses)
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2-cloudwatch-profile"
  role = aws_iam_role.ec2_cloudwatch_role.name
}

# CloudWatch Log Group for EC2 Application Logs
resource "aws_cloudwatch_log_group" "app_log_group" {
  name              = "/aws/ec2/webapp-logs"
  retention_in_days = 1 # Cost-optimized
}

# SSM Parameter to store CloudWatch Agent configuration
resource "aws_ssm_parameter" "cw_agent_config" {
  name = "AmazonCloudWatch-linux-webapp"
  type = "SecureString"
  value = jsonencode({
    logs = {
      logs_collected = {
        files = {
          collect_list = [
            {
              file_path       = "/var/log/cloud-init-output.log"
              log_group_name  = aws_cloudwatch_log_group.app_log_group.name
              log_stream_name = "{instance_id}"
            }
          ]
        }
      }
    }
  })
}
