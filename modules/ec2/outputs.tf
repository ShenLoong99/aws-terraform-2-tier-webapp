output "public_ips" {
  description = "Public IP addresses of the ASG instances"
  value       = data.aws_instances.asg_instances.public_ips
}

output "instance_ids" {
  description = "IDs of the ASG instances"
  value       = data.aws_instances.asg_instances.ids
}
