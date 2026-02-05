output "alb_sg_id" {
  description = "The ID of the ALB security group"
  value       = aws_security_group.alb_sg.id
}

output "nodes_sg_id" {
  description = "The ID of the worker nodes security group"
  value       = aws_security_group.nodes_sg.id
}