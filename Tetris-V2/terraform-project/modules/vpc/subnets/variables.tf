variable "vpc_id" {}
variable "cluster_name" {}
variable "public_cidrs" { type = list(string) }
variable "private_cidrs" { type = list(string) }
variable "azs" { type = list(string) }
