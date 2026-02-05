module "vpc_module" {
  source        = "./modules/vpc"
  cluster_name  = var.eks_cluster_name
  vpc_cidr      = var.vpc_cidr
  public_cidrs  = var.public_subnet_cidr
  private_cidrs = var.private_subnet_cidr
  azs           = var.availability_zones
}
module "iam_module" {
  source       = "./modules/iam"
  cluster_name = var.eks_cluster_name
}

module "security_groups" {
  source       = "./modules/security-groups"
  vpc_id       = module.vpc_module.vpc_id # بياخد الـ ID من موديول الـ VPC
  cluster_name = var.eks_cluster_name
}

module "eks_module" {
  source           = "./modules/eks"
  cluster_name     = var.eks_cluster_name
  cluster_role_arn = module.iam_module.cluster_role_arn
  node_role_arn    = module.iam_module.node_role_arn
  subnet_ids       = module.vpc_module.private_subnet_ids # الـ Nodes بتتحط في الـ Private للأمان
  nodes_sg_id      = module.security_groups.nodes_sg_id
}