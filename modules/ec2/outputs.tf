output "public_ips" {
  description = "Public IP addresses of the EC2 instances"
  value       = aws_instance.app_server[*].public_ip
}

output "instance_ids" {
  description = "IDs of the EC2 instances"
  value       = aws_instance.app_server[*].id
}