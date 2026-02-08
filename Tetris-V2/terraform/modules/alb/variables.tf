variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs"
  type        = list(string)
}

variable "alb_name" {
  description = "Name of the ALB"
  type        = string
  default     = "tetris-alb"
}

variable "target_group_name" {
  description = "Name of the target group"
  type        = string
  default     = "tetris-tg"
}

variable "target_port" {
  description = "Port for target group"
  type        = number
  default     = 80
}

variable "health_check_path" {
  description = "Health check path"
  type        = string
  default     = "/"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
