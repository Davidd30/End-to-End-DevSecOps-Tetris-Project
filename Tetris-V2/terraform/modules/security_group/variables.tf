variable "vpc_id" {
  description = "VPC ID where security groups will be created"
  type        = string
}

variable "eks_cluster_name" {
  description = "EKS cluster name (used for naming security groups)"
  type        = string
}
