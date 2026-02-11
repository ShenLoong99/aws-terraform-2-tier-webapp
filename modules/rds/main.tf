resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = var.aws_db_subnet_group_name
  subnet_ids = var.private_subnet_ids

  tags = {
    Name = var.aws_db_subnet_group_tags["Name"]
  }
}

resource "aws_db_instance" "mysql" {
  # checkov:skip=CKV_AWS_118:Enhanced monitoring is disabled to simplify IAM management and stay within CloudWatch free ingestion limits for this dev environment.
  # checkov:skip=CKV_AWS_293:Deletion protection is disabled to allow for easy cleanup and cost management via 'terraform destroy' in this development environment.
  # checkov:skip=CKV_AWS_161:IAM Authentication is disabled to keep the application code simple. Credentials are currently passed via variables, with a plan to migrate to AWS Secrets Manager in the next iteration.
  allocated_storage               = var.allocated_storage
  max_allocated_storage           = 0 # DISABLE AUTOSCALING ---
  engine                          = var.engine
  engine_version                  = "8.0"
  instance_class                  = "db.t3.micro" # Free Tier Eligible
  db_name                         = var.db_name
  username                        = var.username
  password                        = var.db_password # Use Vault/SecretMgr in real prod!
  db_subnet_group_name            = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids          = [var.rds_sg_id]
  skip_final_snapshot             = true                              # For dev/test, avoid extra snapshot costs
  auto_minor_version_upgrade      = true                              # Keep minor versions updated
  storage_encrypted               = true                              # Always enable encryption
  enabled_cloudwatch_logs_exports = ["error", "general", "slowquery"] # Monitor these logs
  copy_tags_to_snapshot           = true                              # Keep tags on snapshots
  multi_az                        = false                             # Disabled for cost-saving in dev/test
  performance_insights_enabled    = false                             # Can incur costs outside free tier
  monitoring_interval             = 0                                 # Disable Enhanced Monitoring
  backup_retention_period         = 1                                 # Reduce backup storage to min
  delete_automated_backups        = true
}
