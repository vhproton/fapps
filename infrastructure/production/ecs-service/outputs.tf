output "target_group_arn" {
  value = aws_lb_target_group.target_group.arn
}

output "target_group_id" {
  value = aws_lb_target_group.target_group.id
}

output "target_group_arn_suffix" {
  value = aws_lb_target_group.target_group.arn_suffix
}

output "listener_arn" {
  value = aws_lb_listener.lb_listener.arn
}

output "listener_id" {
  value = aws_lb_listener.lb_listener.id
}
