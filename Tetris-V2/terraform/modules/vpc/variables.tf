variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string
  default     = "dev"
}
