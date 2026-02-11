output "public_ips" {
  description = "Public IP addresses of the ASG instances"
  value       = data.aws_instances.asg_instances.public_ips
}

output "instance_ids" {
  description = "IDs of the ASG instances"
  value       = data.aws_instances.asg_instances.ids
}

output "selected_ami_name" {
  description = "The name of the selected Amazon Linux 2 AMI"
  value       = data.aws_ami.latest_amazon_linux.name
}

output "selected_ami_id" {
  description = "The ID of the selected Amazon Linux 2 AMI"
  value       = data.aws_ami.latest_amazon_linux.id
}
