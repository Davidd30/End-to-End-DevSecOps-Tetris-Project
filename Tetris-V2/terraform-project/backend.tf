terraform {
  backend "s3" {
    bucket         = "beshoy-eks-state-unique-id"  
    key            = "eks/terraform.tfstate"    
    region         = "us-east-1"
    dynamodb_table = "terraform-lock"             
    encrypt        = true                         
  }
}