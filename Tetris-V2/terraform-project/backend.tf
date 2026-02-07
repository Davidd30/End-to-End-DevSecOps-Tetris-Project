terraform {
  backend "s3" {
    bucket         = "terraform-state-rina-123456789012-us-east-1"  
    key            = "eks/terraform.tfstate"    
    region         = "us-east-1"
    encrypt        = true
    use_lockfile   = true
  }
}
