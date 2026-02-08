output "worker_nodes_sg_id" {
  description = "Security group ID for EKS worker nodes (EC2s in private subnets)"
  value       = aws_security_group.worker_nodes.id
}


