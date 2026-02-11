resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = var.aws_db_subnet_group_name
  subnet_ids = var.private_subnet_ids

  tags = {
    Name = var.aws_db_subnet_group_tags["Name"]
  }
}

resource "aws_db_instance" "mysql" {
  allocated_storage      = 20
  engine                 = var.engine
  engine_version         = "8.0"
  instance_class         = var.db_instance_class
  db_name                = var.db_name
  username               = var.username
  password               = var.db_password # Use Vault/SecretMgr in real prod!
  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids = [var.rds_sg_id]
  skip_final_snapshot    = true
  # multi_az               = true # For production, consider enabling Multi-AZ
  multi_az = false # Disabled for cost-saving in dev/test
}
