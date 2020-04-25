# -----------------------------------------------------------------------------
# CREATE TARGET GROUP AND ATTACHMENT
# -----------------------------------------------------------------------------

resource "aws_lb_target_group" "target_group" {
  name                 = "${data.template_file.environment.rendered}-${data.template_file.service.rendered}-${var.external_port}"
  port                 = var.internal_port
  protocol             = "HTTP"
  vpc_id               = data.terraform_remote_state.network.outputs.vpc_id
  deregistration_delay = var.deregistration_delay

  health_check {
    matcher             = var.matcher
    interval            = var.interval
    port                = var.port
    protocol            = "HTTP"
    path                = var.health_check_path
    timeout             = var.timeout
    healthy_threshold   = var.healthy_threshold
    unhealthy_threshold = var.unhealthy_threshold
  }
}

resource "aws_lb_listener" "lb_listener" {
  load_balancer_arn = data.terraform_remote_state.alb.outputs.load_balancer_arn
  port              = var.external_port
  protocol          = "HTTPS"
  ssl_policy        = var.ssl_policy
  certificate_arn   = data.terraform_remote_state.alb.outputs.ssl_certificate_arn

  default_action {
    target_group_arn = aws_lb_target_group.target_group.arn
    type             = "forward"
  }
}

# -----------------------------------------------------------------------------
# CREATE ECS SERVICE IAM ROLE
# -----------------------------------------------------------------------------

resource "aws_iam_role" "ecs_task_role" {
  name                = "${data.template_file.environment.rendered}-${data.template_file.service.rendered}-ecs-task"
  assume_role_policy  = data.template_file.ecs_task_policy.rendered
}

# -----------------------------------------------------------------------------
# CREATE TASK DEFINITION
# -----------------------------------------------------------------------------

resource "aws_ecs_task_definition" "task_definition" {
  family                = data.template_file.service.rendered
  container_definitions = data.template_file.ecs_task_http.rendered
  task_role_arn         = aws_iam_role.ecs_task_role.arn
}

# -----------------------------------------------------------------------------
# CREATE THE SERVICE
# -----------------------------------------------------------------------------

resource "aws_ecs_service" "ecs_service" {
  name    = data.template_file.service.rendered
  cluster = data.terraform_remote_state.ecs_cluster.outputs.ecs_cluster_id

  task_definition                    = aws_ecs_task_definition.task_definition.arn
  desired_count                      = var.desired_count
  deployment_minimum_healthy_percent = var.deployment_minimum_healthy_percent
  deployment_maximum_percent         = var.deployment_maximum_percent
  health_check_grace_period_seconds  = var.health_check_grace_period_seconds

  load_balancer {
    target_group_arn = aws_lb_target_group.target_group.arn
    container_name   = "${data.template_file.service.rendered}-nginx"
    container_port   = var.lb_container_port
  }

  tags = {
    Name              = "${data.template_file.environment.rendered}-${data.template_file.service.rendered}"
    ops_terraformed   = var.ops_terraformed
    ops_environment   = data.template_file.environment.rendered
    ops_service       = data.template_file.service.rendered
  }
}

# -----------------------------------------------------------------------------
# ECS SERVICE MONITORING
# -----------------------------------------------------------------------------

resource "aws_cloudwatch_metric_alarm" "memory_utilization_warning" {
  alarm_name          = "${data.template_file.environment.rendered}-${data.template_file.service.rendered}-ECS-service-memory-util-warning"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.warning_evaluation_period
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = var.warning_period
  statistic           = "Average"
  threshold           = var.warning_threshold

  dimensions = {
    ClusterName = data.terraform_remote_state.ecs_cluster.outputs.ecs_cluster_name
    ServiceName = aws_ecs_service.ecs_service.name
  }

  alarm_description         = "Alerts if the memory utilization is above ${var.warning_threshold}% of ECS task reserved memory for ${var.warning_evaluation_period * var.warning_period / 60} minutes"
  alarm_actions             = [data.terraform_remote_state.sns_topics.outputs.ecs_sns_topic_arn]  # Send the a SNS topic which will trigger an alarm
  ok_actions                = [data.terraform_remote_state.sns_topics.outputs.ecs_sns_topic_arn]
  insufficient_data_actions = [data.terraform_remote_state.sns_topics.outputs.ecs_sns_topic_arn]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_cloudwatch_metric_alarm" "memory_utilization_critical" {
  alarm_name          = "${data.template_file.environment.rendered}-${data.template_file.service.rendered}-ECS-service-memory-util-critical"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.critical_evaluation_period
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = var.critical_period
  statistic           = "Average"
  threshold           = var.critical_threshold

  dimensions = {
    ClusterName = data.terraform_remote_state.ecs_cluster.outputs.ecs_cluster_name
    ServiceName = aws_ecs_service.ecs_service.name
  }

  alarm_description         = "Alerts if the memory utilization is above ${var.critical_threshold}% of ECS task reserved memory for ${var.critical_evaluation_period * var.critical_period / 60} minutes"
  alarm_actions             = [data.terraform_remote_state.sns_topics.outputs.ecs_sns_topic_arn]  # Send the a SNS topic which will trigger an alarm
  ok_actions                = [data.terraform_remote_state.sns_topics.outputs.ecs_sns_topic_arn]
  insufficient_data_actions = [data.terraform_remote_state.sns_topics.outputs.ecs_sns_topic_arn]

  lifecycle {
    create_before_destroy = true
  }
}
