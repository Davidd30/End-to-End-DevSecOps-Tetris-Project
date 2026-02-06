# 1. الـ EKS Cluster (Control Plane)
resource "aws_eks_cluster" "this" {
  name     = var.cluster_name
  role_arn = var.cluster_role_arn
  version  = "1.33" # نسخة مستقرة

  vpc_config {
    subnet_ids         = var.subnet_ids
    security_group_ids = [var.nodes_sg_id]
  }
}

# 2. الـ Node Group (السيرفرات اللي هتشيل اللعبة)
resource "aws_eks_node_group" "this" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${var.cluster_name}-nodes"
  node_role_arn   = var.node_role_arn
  subnet_ids      = var.subnet_ids

  scaling_config {
    desired_size = 2 # يبدأ بسيرفرين
    max_size     = 3 # يفتح لـ 3 لو فيه ضغط
    min_size     = 1 # ميفضلش أقل من واحد
  }

  instance_types = ["t3.medium"] # مناسبة جداً للعبة التيتريس والتجارب

  capacity_type = "ON_DEMAND"
}