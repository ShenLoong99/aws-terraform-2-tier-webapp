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
    http = {
      source  = "hashicorp/http"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}
