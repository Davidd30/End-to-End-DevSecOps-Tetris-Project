################################################################################
# ALB Module (depends on: VPC, Subnets)
################################################################################
module "alb" {
  source = "./modules/alb"

  vpc_id              = module.vpc.vpc_id
  public_subnet_ids   = module.subnet.public_subnet_ids
  alb_name            = "rina-tetris-alb"
  target_group_name   = "rina-tetris-tg"
  target_port         = 80
  health_check_path   = "/"

  tags = {
    Environment = "production"
    Project     = "tetris"
  }

  depends_on = [module.subnet]
}

################################################################################
# Outputs
################################################################################
output "alb_dns_name" {
  value       = module.alb.alb_dns_name
  description = "DNS name of the ALB"
}

output "alb_arn" {
  value       = module.alb.alb_arn
  description = "ARN of the ALB"
}

output "target_group_arn" {
  value       = module.alb.target_group_arn
  description = "ARN of the target group"
}

output "alb_security_group_id" {
  value       = module.alb.security_group_id
  description = "Security group ID of the ALB"
}
