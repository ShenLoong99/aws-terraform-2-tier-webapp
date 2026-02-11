# Query data about the current AWS account
data "aws_caller_identity" "current" {}

# The VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  tags                 = { Name = "webapp-2-tier-vpc" }
}

# Default Security Group (Deny All)
resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.main.id

  # Leaving ingress/egress empty effectively denies all traffic
  # to/from anything accidentally associated with this group.

  tags = {
    Name = "default-sg-restricted"
  }
}

# The Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "main-igw" }
}

# Public Subnets (AZ-a and AZ-b)
resource "aws_subnet" "public" {
  # checkov:skip=CKV_AWS_130:Public IP auto-assignment is enabled to allow EC2 instances to reach the internet for updates without a NAT Gateway (Cost Optimization).
  count                   = length(var.public_cidrs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_cidrs[count.index]
  availability_zone       = var.azs[count.index]
  map_public_ip_on_launch = true
  tags                    = { Name = "public-subnet-${count.index}" }
}

# Private Subnets for RDS
resource "aws_subnet" "private" {
  count             = length(var.private_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_cidrs[count.index]
  availability_zone = var.azs[count.index]
  tags              = { Name = "private-subnet-${count.index}" }
}

# Route Table for Public Subnets
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

# Associate Public Subnets with the Route Table
resource "aws_route_table_association" "public_assoc" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public_rt.id
}

# The Flow Log Resource
resource "aws_flow_log" "vpc_debug_logs" {
  iam_role_arn    = aws_iam_role.flow_log_role.arn # Requires an IAM role
  log_destination = aws_cloudwatch_log_group.flow_log_group.arn
  traffic_type    = "REJECT" # Options: ALL, ACCEPT, REJECT
  vpc_id          = aws_vpc.main.id

  # Optional: Increase capture interval to reduce volume (60 or 600 seconds)
  max_aggregation_interval = 600

  # Ensure the Flow Log is destroyed BEFORE the log group
  depends_on = [aws_cloudwatch_log_group.flow_log_group]
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "flow_log_group" {
  name              = "/aws/vpc/flow-logs-debug"
  retention_in_days = 1
}

# IAM Role for Flow Logs
resource "aws_iam_role" "flow_log_role" {
  name = "vpc-flow-log-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "vpc-flow-logs.amazonaws.com" }
    }]
  })
}

# IAM Policy for the Role
resource "aws_iam_role_policy" "flow_log_policy" {
  # checkov:skip=CKV_AWS_355:Wildcard is required for logs:DescribeLogGroups and logs:CreateLogGroup as they do not support resource-level permissions.
  name = "vpc-flow-log-policy"
  role = aws_iam_role.flow_log_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # Statement A: Actions that support ARNs (Writing logs)
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Effect   = "Allow"
        Resource = "${aws_cloudwatch_log_group.flow_log_group.arn}:*"
        Condition = {
          StringEquals = {
            "aws:PrincipalAccount" = data.aws_caller_identity.current.account_id
          }
        }
      },
      {
        # Statement B: Discovery actions (Read-only)
        Action = [
          "logs:DescribeLogGroups"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}
