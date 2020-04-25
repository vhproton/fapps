output "load_balancer_name" {
  value = aws_lb.alb.name
}

output "load_balancer_arn" {
  value = aws_lb.alb.arn
}

output "load_balancer_dns_name" {
  value = aws_lb.alb.dns_name
}

output "load_balancer_zone_id" {
  value = aws_lb.alb.zone_id
}

output "load_balancer_arn_suffix" {
  value = aws_lb.alb.arn_suffix
}

output "alb_security_group_id" {
  value = aws_security_group.alb_access.id
}

output "target_group_arn_shared" {
  value = aws_lb_target_group.target_group_default_shared.arn
}

output "target_group_arn_shared" {
  value = aws_lb_target_group.target_group_default_shared.arn
}

output "target_group_id_shared" {
  value = aws_lb_target_group.target_group_default_shared.id
}

output "target_group_arn_suffix_shared" {
  value = aws_lb_target_group.target_group_default_shared.arn_suffix
}

output "listener_id_shared" {
  value = aws_lb_listener.alb_listener_shared.id
}

output "ssl_certificate_arn" {
  value = aws_acm_certificate.fapps_ssl_cert.arn
}