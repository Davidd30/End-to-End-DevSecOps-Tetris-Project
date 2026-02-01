variable "public_subnet_ids" {
  type        = list(string)
  description = "Public subnet ids to associate with public RT"
}

variable "public_route_table_id" {
  type        = string
  description = "ID of the public route table"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "Private subnet ids to associate with private RTs"
}

variable "private_route_table_id" {
  type        = string
  description = "Private route table id (shared by all private subnets)"
}