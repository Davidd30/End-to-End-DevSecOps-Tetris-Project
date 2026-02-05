resource "aws_internet_gateway" "igw" {
  vpc_id = var.vpc_id
  tags   = { Name = "${var.cluster_name}-igw" }
}

resource "aws_eip" "nat" { domain = "vpc" }

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = var.public_subnet_id
  tags          = { Name = "${var.cluster_name}-nat" }
}
