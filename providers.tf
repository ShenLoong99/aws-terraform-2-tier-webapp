terraform {
  required_version = ">= 1.5.0"
  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "my-terraform-aws-projects-2025"

    workspaces {
      name = "aws-terraform-2-tier-webapp"
    }
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "Project-5-Two-Tier-WebApp"
      Environment = "Development"
      Owner       = "ShenLoong"
      ManagedBy   = "Terraform"
      CostCenter  = "Cloud-Learning"
    }
  }
}
