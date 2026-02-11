output "db_instance_endpoint" {
  description = "The connection endpoint for the RDS instance"
  value       = aws_db_instance.mysql.endpoint
}

output "db_name" {
  description = "The name of the database"
  value       = aws_db_instance.mysql.db_name
}

output "db_username" {
  description = "The master username for the database"
  value       = aws_db_instance.mysql.username
}

output "db_host" {
  description = "The connection endpoint for the database"
  # Use .address for just the hostname, or .endpoint for hostname:port
  value = aws_db_instance.mysql.address
}

output "db_port" {
  description = "The port for the database"
  value       = aws_db_instance.mysql.port
}
