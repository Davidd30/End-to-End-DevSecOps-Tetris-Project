terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.97.0"
    }
  }

  backend "s3" {
    bucket       = "practice-eks-install-bucket-rina-2026-01"
    key          = "backend/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
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
}
