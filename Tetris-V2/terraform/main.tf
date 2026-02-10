terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.25"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.13"
    }

    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }

backend "s3" {
  bucket  = "terraform-state-rina-123456789012-us-east-1"
  key     = "eks/terraform.tfstate"
  region  = "us-east-1"
  encrypt = true
}

}
provider "aws" {
  region = var.region
}
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(
    module.eks.cluster_certificate_authority
  )
  token = data.aws_eks_cluster_auth.cluster.token
}
provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(
      module.eks.cluster_certificate_authority
    )
    token = data.aws_eks_cluster_auth.cluster.token
  }
}
################################################################################
# DATA SOURCE: EKS cluster auth token
################################################################################
data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_name
  depends_on = [module.eks]
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


# 1. Get the OIDC Provider URL from the EKS cluster
# Data source to fetch the thumbprint for OIDC provider
data "tls_certificate" "cluster" {
  url = module.eks.oidc_issuer
}

# 2. Create the OIDC Provider for IRSA (IAM Roles for Service Accounts)
resource "aws_iam_openid_connect_provider" "oidc" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.cluster.certificates[0].sha1_fingerprint]
  url             = module.eks.oidc_issuer

  depends_on = [module.eks]
}

# 3. Create the IAM Role with a Trust Policy for the Service Account
resource "aws_iam_role" "external_dns" {
  name = "external-dns-controller-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.oidc.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            # This ensures only the service account in the 'kube-system' namespace can use this role
            "${replace(aws_iam_openid_connect_provider.oidc.url, "https://", "")}:sub": "system:serviceaccount:kube-system:external-dns"
          }
        }
      }
    ]
  })
}

# 3. Attach the Route53 permissions to the role
resource "aws_iam_role_policy" "external_dns_permissions" {
  name = "external-dns-permissions"
  role = aws_iam_role.external_dns.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["route53:ChangeResourceRecordSets"]
        Effect   = "Allow"
        Resource = ["arn:aws:route53:::hostedzone/Z09342907YP1AOPYGRHO"] # Or limit to your specific ZoneID
      },
      {
        Action   = ["route53:ListHostedZones", "route53:ListResourceRecordSets"]
        Effect   = "Allow"
        Resource = ["*"]
      }
    ]
  })
}

resource "helm_release" "external_dns" {
  name       = "external-dns"
  repository = "https://kubernetes-sigs.github.io/external-dns/"
  chart      = "external-dns"
  namespace  = "kube-system"

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.external_dns.arn
  }

  set {
    name  = "provider"
    value = "aws"
  }

  set {
    name  = "source"
    value = "ingress" # Tells it to look at Ingress objects
  }

  set {
    name  = "domainFilters[0]"
    value = "davidgirgis.online" # Limits it to your domain
  }
}

################################################################################
# AWS Load Balancer Controller IAM Role
################################################################################
resource "aws_iam_role" "aws_load_balancer_controller" {
  name = "aws-load-balancer-controller-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.oidc.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${replace(aws_iam_openid_connect_provider.oidc.url, "https://", "")}:sub": "system:serviceaccount:kube-system:aws-load-balancer-controller"
          }
        }
      }
    ]
  })
}

# Attach the AWS managed policy for Load Balancer Controller
resource "aws_iam_role_policy_attachment" "aws_load_balancer_controller" {
  role       = aws_iam_role.aws_load_balancer_controller.name
  policy_arn = "arn:aws:iam::391369718038:policy/AWSLoadBalancerControllerIAMPolicy"
}

resource "kubernetes_service_account" "aws_lbc" {
  metadata {
    name      = "aws-load-balancer-controller"
    namespace = "kube-system"
    annotations = {
      # This links the K8s SA to the AWS IAM Role
      "eks.amazonaws.com/role-arn" = aws_iam_role.aws_load_balancer_controller.arn
    }
  }
}

# NOTE: The AWS Load Balancer Controller Helm release is deployed manually via eksctl