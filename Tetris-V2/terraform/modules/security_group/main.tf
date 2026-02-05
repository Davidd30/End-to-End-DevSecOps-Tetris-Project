##################################
# Worker Nodes SG (EC2s in private subnets)
##################################
resource "aws_security_group" "worker_nodes" {
  name        = "${var.eks_cluster_name}-worker-nodes-sg"
  description = "Security group for EKS worker nodes (EC2s) in private subnets"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.eks_cluster_name}-worker-nodes-sg"
  }
}

# Allow traffic from ALB to worker nodes (NodePort range + HTTP)
resource "aws_security_group_rule" "worker_from_alb" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb.id
  security_group_id        = aws_security_group.worker_nodes.id
  description              = "Allow HTTP from ALB to worker nodes"
}

resource "aws_security_group_rule" "worker_from_alb_nodeport" {
  type                     = "ingress"
  from_port                = 30000
  to_port                  = 32767
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb.id
  security_group_id        = aws_security_group.worker_nodes.id
  description              = "Allow NodePort range from ALB to worker nodes"
}

# Allow traffic between EC2 worker nodes (node-to-node on NodePort range)
resource "aws_security_group_rule" "worker_from_worker" {
  type              = "ingress"
  from_port         = 30000
  to_port           = 32767
  protocol          = "tcp"
  self              = true
  security_group_id = aws_security_group.worker_nodes.id
  description       = "Allow NodePort traffic between worker nodes"
}

# Egress: allow all outbound (pulling images, cluster communication, etc.)
resource "aws_security_group_rule" "worker_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.worker_nodes.id
  description       = "Allow all outbound traffic"
}
