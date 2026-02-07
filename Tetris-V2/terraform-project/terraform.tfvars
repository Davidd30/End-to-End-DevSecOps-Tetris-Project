# values of vars 
region              = "us-east-1"
vpc_cidr            = "10.0.0.0/16"

# زودنا Subnet تالتة لكل نوع عشان نغطي us-east-1c
public_subnet_cidr  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
private_subnet_cidr = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]

# تفعيل المنطقة الثالثة
availability_zones  = ["us-east-1a", "us-east-1b", "us-east-1c"]

eks_cluster_name    = "tetris-project"