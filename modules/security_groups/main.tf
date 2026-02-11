# Fetch your current public IP address
data "http" "my_ip" {
  url = "https://ipv4.icanhazip.com"
}

# ALB Security Group
resource "aws_security_group" "alb_sg" {
  # checkov:skip=CKV_AWS_260:Port 80 is open to allow public demo access. HTTPS (443) is preferred but requires a custom domain/certificate which is out of scope for this Free Tier project.
  # checkov:skip=CKV2_AWS_5:This security group is attached to a resource in another module. Checkov fails to detect the cross-module attachment.
  name        = "alb-sg"
  description = "Allow HTTP inbound traffic"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow public HTTP traffic from the internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic to any destination"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# EC2 Security Group (Allows traffic from ALB only)
resource "aws_security_group" "ec2_sg" {
  # checkov:skip=CKV2_AWS_5:This security group is attached to a resource in another module. Checkov fails to detect the cross-module attachment.
  name        = "ec2-sg"
  description = "Allow traffic from ALB"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow Node.js traffic from the ALB Security Group only"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    # CRITICAL: Use 'security_groups' (the ID of the ALB SG)
    # instead of 'cidr_blocks'. This blocks the general internet.
    security_groups = [aws_security_group.alb_sg.id]
  }

  ingress {
    description = "Allow SSH access from the Administrator specific public IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    # chomp() removes the hidden newline character from the API response
    cidr_blocks = ["${chomp(data.http.my_ip.response_body)}/32"]
  }

  egress {
    description = "Allow all outbound traffic for updates and external API communication"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# RDS Security Group
resource "aws_security_group" "rds_sg" {
  # checkov:skip=CKV2_AWS_5:This security group is attached to a resource in another module. Checkov fails to detect the cross-module attachment.
  name        = "rds-sg"
  description = "Allow MySQL traffic from EC2 only"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow MySQL protocol access from the Web Server Security Group"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    # This ensures ONLY instances in the ec2_sg can talk to the database
    security_groups = [aws_security_group.ec2_sg.id]
  }

  egress {
    description = "Allow all outbound traffic (standard RDS egress)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
