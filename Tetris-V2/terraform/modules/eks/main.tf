##################################
# Create EKS Cluster (role is provided by an external/iam module)
##################################
resource "aws_eks_cluster" "main" {
  name     = var.eks_cluster_name
  version  = var.cluster_version
  role_arn = var.cluster_role_arn

  vpc_config {
    subnet_ids = var.subnet_ids
  }
}

##################################
# EKS Managed Node Groups (node role is provided externally)
##################################
resource "aws_eks_node_group" "node_groups" {
  for_each = var.node_groups

  cluster_name    = aws_eks_cluster.main.name
  node_group_name = each.key
  node_role_arn   = var.node_role_arn
  subnet_ids      = var.subnet_ids

  instance_types = each.value.instance_types
  capacity_type  = each.value.capacity_type

  scaling_config {
    desired_size = each.value.scaling_config.desired_size
    max_size     = each.value.scaling_config.max_size
    min_size     = each.value.scaling_config.min_size
  }
}
