# إنشاء الـ VPC نفسها
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = { Name = "${var.cluster_name}-vpc" }
}

# 1. مناداة موديول السابنتس
module "subnets" {
  source        = "./subnets"
  vpc_id        = aws_vpc.this.id
  cluster_name  = var.cluster_name
  public_cidrs  = var.public_cidrs
  private_cidrs = var.private_cidrs
  azs           = var.azs
}

# 2. مناداة موديول البوابات
module "gateways" {
  source           = "./gate-ways"
  vpc_id           = aws_vpc.this.id
  cluster_name     = var.cluster_name
  public_subnet_id = module.subnets.public_ids[0] # بياخد أول سابنت عامة للـ NAT
}

# 3. مناداة موديول التوجيه
module "routing" {
  source             = "./routing"
  vpc_id             = aws_vpc.this.id
  igw_id             = module.gateways.igw_id
  nat_id             = module.gateways.nat_id
  public_subnet_ids  = module.subnets.public_ids
  private_subnet_ids = module.subnets.private_ids
}



