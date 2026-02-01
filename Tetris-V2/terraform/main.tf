terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.97.0"
    }
  }

  backend "s3" {
    bucket       = "practice-eks-install-bucket-rina-2026-01"
    key          = "eks/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}

provider "aws" {
  region = var.region
}

################################################################################
# LAYER 1: VPC (foundation - no dependencies)
################################################################################
module "vpc" {
  source = "./modules/vpc"

  vpc_cidr = var.vpc_cidr
}

################################################################################
# LAYER 2: Subnets (depends on VPC)
################################################################################
module "subnet" {
  source = "./modules/subnet"

  vpc_id               = module.vpc.vpc_id
  availability_zones   = var.availability_zones
  public_subnet_cidrs  = var.public_subnet_cidr
  private_subnet_cidrs = var.private_subnet_cidr

  depends_on = [module.vpc]
}

################################################################################
# LAYER 3: Route tables, NAT gateways, IGW (depends on VPC + Subnets)
################################################################################
module "route_table" {
  source = "./modules/route_table"

  vpc_id             = module.vpc.vpc_id
  public_subnet_ids  = module.subnet.public_subnet_ids
  private_subnet_ids = module.subnet.private_subnet_ids

  depends_on = [module.vpc, module.subnet]
}

################################################################################
# LAYER 4: Route table associations (depends on Subnets + Route tables)
################################################################################
module "route_assoc" {
  source = "./modules/route_table_association"

  public_subnet_ids     = module.subnet.public_subnet_ids
  public_route_table_id = module.route_table.public_route_table_id

  private_subnet_ids     = module.subnet.private_subnet_ids
  private_route_table_id = module.route_table.private_route_table_id

  depends_on = [module.subnet, module.route_table]
}

################################################################################
# LAYER 5: IAM roles (no network dependency - can run in parallel with networking)
################################################################################
module "iam" {
  source = "./modules/iam"

  eks_cluster_name = var.eks_cluster_name
}

################################################################################
# LAYER 6: EKS cluster + node groups (depends on: networking + IAM)
# Must wait for route associations so private subnets have NAT for pulling images
################################################################################
module "eks" {
  source = "./modules/eks"

  eks_cluster_name = var.eks_cluster_name
  cluster_version  = var.cluster_version
  subnet_ids       = module.subnet.private_subnet_ids
  node_groups      = var.node_groups

  cluster_role_arn = module.iam.cluster_role_arn
  node_role_arn    = module.iam.node_role_arn

  depends_on = [
    module.route_assoc,
    module.iam
  ]
}
