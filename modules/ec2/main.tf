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
  user_data                   = file("${path.root}/scripts/user_data.sh")
  user_data_replace_on_change = true
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name
  key_name                    = var.key_name

  tags = { Name = "App-Server-${count.index}" }
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