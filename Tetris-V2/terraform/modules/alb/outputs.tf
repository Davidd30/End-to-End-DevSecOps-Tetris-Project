output "alb_id" {
  value       = aws_lb.main.id
  description = "ID of the ALB"
}

output "alb_arn" {
  value       = aws_lb.main.arn
  description = "ARN of the ALB"
}

output "alb_dns_name" {
  value       = aws_lb.main.dns_name
  description = "DNS name of the ALB"
}

output "alb_zone_id" {
  value       = aws_lb.main.zone_id
  description = "Zone ID of the ALB"
}

output "target_group_id" {
  value       = aws_lb_target_group.main.id
  description = "ID of the target group"
}

output "target_group_arn" {
  value       = aws_lb_target_group.main.arn
  description = "ARN of the target group"
}

output "target_group_name" {
  value       = aws_lb_target_group.main.name
  description = "Name of the target group"
}

output "security_group_id" {
  value       = aws_security_group.alb_sg.id
  description = "ID of the ALB security group"
}

output "listener_arn" {
  value       = aws_lb_listener.http.arn
  description = "ARN of the HTTP listener"
}
