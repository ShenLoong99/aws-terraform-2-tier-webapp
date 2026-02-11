variable "vpc_id" {
  description = "The ID of the VPC"
  type        = string
}

# Retrieve from TFC variable
variable "admin_ip" {
  description = "CIDR block for admin IPs allowed to access resources"
  type        = string
}
