output "vpc_id" {
  value = aws_vpc.vpc.id
}

output "subnet_dmz_id" {
  value = aws_subnet.subnet_dmz.id
}

output "public_routing_id" {
  value = aws_route_table.public_routing.id
}

output "vpc_flow_logs_name" {
  value = aws_s3_bucket.vpc_flow_logs.id
}

output "vpc_flow_logs_arn" {
  value = aws_s3_bucket.vpc_flow_logs.arn
}