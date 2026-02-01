output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.eks_vpc.id
}
