# Fetch the latest Amazon Linux 2 AMI
data "aws_ami" "latest_amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name = "name"
    # Change "amzn2-ami-hvm-*" to:
    values = ["al2023-ami-2023*-kernel-6.1-x86_64"]
  }
}

resource "aws_instance" "app_server" {
  count                       = 2
  ami                         = data.aws_ami.latest_amazon_linux.id
  instance_type               = var.instance_type
  subnet_id                   = var.public_subnet_ids[count.index]
  vpc_security_group_ids      = [var.ec2_sg_id]
  user_data_replace_on_change = true
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name
  key_name                    = var.key_name

  user_data = templatefile("${path.module}/scripts/user_data.tftpl", {
    db_host = var.db_host
    db_user = var.db_username
    db_pass = var.db_password
    db_name = var.db_name
    db_port = var.db_port
  })

  # THE CONNECTION
  connection {
    type = "ssh"
    user = "ec2-user"
    # Ensure this points to the .pem file path, not just the AWS key name
    private_key = file("${var.key_name}.pem")
    host        = self.public_ip
  }

  # Create the directory before uploading the file
  provisioner "remote-exec" {
    inline = [
      "mkdir -p /home/ec2-user/app/assets"
    ]
  }

  provisioner "file" {
    source      = "assets/favicon.ico"
    destination = "/home/ec2-user/app/assets/favicon.ico"
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "App-Server-${count.index}"
  }
}

# Instances actually join the Load Balancer
resource "aws_lb_target_group_attachment" "app_attach" {
  count            = 2
  target_group_arn = var.target_group_arn
  target_id        = aws_instance.app_server[count.index].id
  port             = 3000
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

# Create the Instance Profile (This is what the EC2 actually uses)
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2-cloudwatch-profile"
  role = aws_iam_role.ec2_cloudwatch_role.name
}

# Due to the below code will incur cost (not free tier), it is commented out.
# Create a Golden Image (AMI) from a configured Instance
# resource "aws_ami_from_instance" "app_golden_image" {
#   name               = "webapp-golden-image-${formatdate("YYYYMMDD-hhmm", timestamp())}"
#   source_instance_id = "i-0c893775e52c68857" # The ID of your configured instance

#   # Recommended: Stop the instance to ensure a clean filesystem state
#   snapshot_without_reboot = false 
# }

# # This allows anyone to find the image YOU created
# data "aws_ami" "golden_image" {
#   most_recent = true
#   owners      = ["871308866502"]  

#   filter {
#     name   = "name"
#     values = ["webapp-golden-image-20260108-0714"]
#   }
# }

# Launch Template and Auto Scaling Group using the Golden AMI
# resource "aws_launch_template" "app_lt" {
#   name_prefix   = "app-server-template-"
#   # Use the AMI created in Step 1 or a data source to find the latest
#   image_id      = aws_ami_from_instance.app_golden_image.id
#   instance_type = var.instance_type
#   key_name      = var.key_name

#   # Network settings move here
#   network_interfaces {
#     associate_public_ip_address = true
#     security_groups             = [var.ec2_sg_id]
#   }

#   # Minimal User Data: Only for dynamic DB variables, not installations
#   user_data = base64encode(templatefile("${path.root}/scripts/user_data.tftpl", {
#     db_host = var.db_host
#     db_user = var.db_username
#     db_pass = var.db_password
#     db_name = var.db_name
#     db_port = var.db_port
#   }))

#   tag_specifications {
#     resource_type = "instance"
#     tags = { Name = "App-Server-LT" }
#   }

#   lifecycle {
#     create_before_destroy = true
#   }
# }

# Auto Scaling Group to manage EC2 Instances
# resource "aws_autoscaling_group" "app_asg" {
#   desired_capacity    = 2
#   max_size            = 4
#   min_size            = 1
#   target_group_arns   = [var.target_group_arn]
#   vpc_zone_identifier = var.public_subnet_ids

#   launch_template {
#     id      = aws_launch_template.app_lt.id
#     version = "$Latest"
#   }

#   # Speed Optimization: Don't wait 5 minutes for the old instance to die
#   health_check_type         = "ELB"
#   health_check_grace_period = 60 # Reduced from 300
# }