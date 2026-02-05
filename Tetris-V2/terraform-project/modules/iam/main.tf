module "cluster_role" {
  source       = "./cluster-role"
  cluster_name = var.cluster_name
}

module "node_role" {
  source       = "./node-role"
  cluster_name = var.cluster_name
}