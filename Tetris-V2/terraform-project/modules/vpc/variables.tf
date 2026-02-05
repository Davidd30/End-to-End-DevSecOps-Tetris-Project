variable "cluster_name" {}
variable "vpc_cidr" {}
variable "public_cidrs" { type = list(string) }
variable "private_cidrs" { type = list(string) }
variable "azs" { type = list(string) }
