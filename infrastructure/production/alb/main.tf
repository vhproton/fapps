# -----------------------------------------------------------------------------
# CREATE DNS ZONE
# -----------------------------------------------------------------------------

resource "aws_route53_zone" "fapps_co" {
  name = "fapps.co"

  tags = {
    Name              = "${data.template_file.environment.rendered}-${data.template_file.service.rendered}"
    ops_terraformed   = var.ops_terraformed
    ops_environment   = data.template_file.environment.rendered
    ops_service       = data.template_file.service.rendered
  }
}

# -----------------------------------------------------------------------------
# CREATE SSL CERTIFICATE & VALIDATION DNS RECORD
# -----------------------------------------------------------------------------

resource "aws_acm_certificate" "fapps_ssl_cert" {
  domain_name       = "*.fapps.co"
  validation_method = "DNS"

  tags = {
    Name              = "${data.template_file.environment.rendered}-${data.template_file.service.rendered}-fapps-co"
    ops_terraformed   = var.ops_terraformed
    ops_environment   = data.template_file.environment.rendered
    ops_service       = data.template_file.service.rendered
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "cert_validation_fapps_co" {
  name    = aws_acm_certificate.fapps_ssl_cert.domain_validation_options.0.resource_record_name
  type    = aws_acm_certificate.fapps_ssl_cert.domain_validation_options.0.resource_record_type
  zone_id = aws_route53_zone.fapps_co.id
  records = [aws_acm_certificate.fapps_ssl_cert.domain_validation_options.0.resource_record_value]
  ttl     = 86400
}

# -----------------------------------------------------------------------------
# CREATE THE SECURITY GROUP THAT CONTROLS WHAT TRAFFIC CAN GO IN AND OUT OF THE ALB
# -----------------------------------------------------------------------------

resource "aws_security_group" "alb_access" {
  name        = "${data.template_file.environment.rendered}-${data.template_file.service.rendered}-alb"
  description = "Security group for ${data.template_file.environment.rendered} ${data.template_file.service.rendered} ALB"
  vpc_id      = data.terraform_remote_state.network.outputs.vpc_id

  tags = {
    Name              = "${data.template_file.environment.rendered}-${data.template_file.service.rendered}-alb"
    ops_terraformed   = var.ops_terraformed
    ops_environment   = data.template_file.environment.rendered
    ops_service       = data.template_file.service.rendered
  }
}

resource "aws_security_group_rule" "allow_all_outbound" {
  type        = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.alb_access.id
}

resource "aws_security_group_rule" "allow_inbound" {
  type        = "ingress"
  from_port   = 443
  to_port     = 443
  protocol    = "TCP"
  cidr_blocks = ["0.0.0.0/0"]
  description = "External 0.0.0.0/0 access to Shared ALB"

  security_group_id = aws_security_group.alb_access.id
}

# -----------------------------------------------------------------------------
# CREATE S3 BUCKET FOR ALB LOGS
# -----------------------------------------------------------------------------

resource "aws_s3_bucket" "alb_logs" {
  bucket = "${data.template_file.environment.rendered}-${data.template_file.service.rendered}-alb-logs"
  acl    = "private"

  tags = {
    Name              = "${data.template_file.environment.rendered}-${data.template_file.service.rendered}-alb-logs"
    ops_terraformed   = var.ops_terraformed
    ops_environment   = data.template_file.environment.rendered
    ops_service       = data.template_file.service.rendered
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_s3_bucket_public_access_block" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# -----------------------------------------------------------------------------
# CREATE THE ALB
# -----------------------------------------------------------------------------

resource "aws_lb" "alb" {
  name                       = "${data.template_file.environment.rendered}-${data.template_file.service.rendered}-alb"
  internal                   = var.internal
  subnets                    = [data.terraform_remote_state.network.outputs.subnet_dmz_id]
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.alb_access.id]
  enable_deletion_protection = true

  access_logs {
    bucket  = aws_s3_bucket.alb_logs.name
    prefix  = data.template_file.service.rendered
    enabled = true
  }

  tags = {
    Name              = "${data.template_file.environment.rendered}-${data.template_file.service.rendered}-alb"
    ops_terraformed   = var.ops_terraformed
    ops_environment   = data.template_file.environment.rendered
    ops_service       = data.template_file.service.rendered
  }
}

# -----------------------------------------------------------------------------
# TARGET GROUPS AND LISTENER
# -----------------------------------------------------------------------------

resource "aws_lb_target_group" "target_group_default_shared" {
  name     = "${substr(data.template_file.environment.rendered, 0, 8)}-cluster-01-shared"
  port     = 443
  protocol = "HTTPS"
  vpc_id   = data.terraform_remote_state.network.outputs.vpc_id
}

resource "aws_lb_listener" "alb_listener_shared" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = var.ssl_policy
  certificate_arn   = aws_acm_certificate.fapps_ssl_cert.arn

  default_action {
    target_group_arn = aws_lb_target_group.target_group_default_shared.arn
    type             = "forward"
  }
}

# -----------------------------------------------------------------------------
# CREATE A ROUTE53 ENTRY
# -----------------------------------------------------------------------------

resource "aws_route53_record" "fapps_co_dns" {
  zone_id = aws_route53_zone.fapps_co.id
  name    = "www.fapps.co"
  type    = "CNAME"
  ttl     = 86400
  records = [aws_lb.alb.dns_name]
}

