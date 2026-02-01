region = "us-east-1"

vpc_cidr = "10.0.0.0/16"

public_subnet_cidr = [
  "10.0.1.0/24",
  "10.0.2.0/24",
  "10.0.3.0/24"
]

private_subnet_cidr = [
  "10.0.101.0/24",
  "10.0.102.0/24",
  "10.0.103.0/24"
]

availability_zones = [
  "us-east-1a",
  "us-east-1b",
  "us-east-1c"
]

eks_cluster_name = "rina-eks-cluster"

cluster_version = "1.29"

node_groups = {
  default = {
    instance_types = ["t3.small"]
    capacity_type  = "ON_DEMAND"

    scaling_config = {
      desired_size = 2
      min_size     = 1
      max_size     = 3
    }
  }
}
