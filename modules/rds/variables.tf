variable "private_subnet_ids" {
  description = "List of private subnet IDs"
  type        = list(string)
}

variable "rds_sg_id" {
  description = "The ID of the RDS security group"
  type        = string
}

variable "db_password" {
  description = "The password for the database"
  type        = string
  sensitive   = true
}

variable "aws_db_subnet_group_name" {
  description = "The name of the DB subnet group"
  type        = string
  default     = "main-rds-subnet-group"
}

variable "engine" {
  description = "The database engine"
  type        = string
  default     = "mysql"
}

variable "db_name" {
  description = "The name of the database"
  type        = string
  default     = "webapp_2_tier_db"
}

variable "username" {
  description = "The username for the database"
  type        = string
  default     = "admin"
}

variable "db_instance_class" {
  description = "The instance type of the RDS database"
  type        = string
}

variable "aws_db_subnet_group_tags" {
  description = "Tags for the DB subnet group"
  type        = map(string)
  default     = { Name = "My DB Subnet Group" }
}