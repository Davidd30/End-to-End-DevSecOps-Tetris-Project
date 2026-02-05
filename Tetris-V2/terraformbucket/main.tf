terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.97.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "terraform_state" {
  bucket = "practice-eks-install-bucket-rina-2026-01"

  lifecycle {
    prevent_destroy = false
  }

  tags = {
    Name        = "terraform-state-bucket"
    Purpose     = "Terraform remote backend"
    Environment = "shared"
  }
}
