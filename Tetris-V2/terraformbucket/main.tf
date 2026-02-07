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
  bucket = "terraform-state-rina-123456789012-us-east-1"

  lifecycle {
    prevent_destroy = false
  }

  tags = {
    Name        = "terraform-state-bucket"
    Purpose     = "Terraform remote backend"
    Environment = "shared"
  }
}

output "s3_bucket_name" {
  value       = aws_s3_bucket.terraform_state.bucket
  description = "Name of the S3 bucket used for Terraform remote state"
}
