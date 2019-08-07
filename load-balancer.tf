resource "aws_alb" "main" {
  count = "${var.enable_lb ? 1 : 0}" ## Load Balancer

  name = "${var.environment}-${var.service_name}"

  internal        = "${var.lb_internal}"
  subnets         = "${var.lb_subnetids}"
  security_groups = "${concat(list(aws_security_group.alb_sg[0].id), var.lb_security_group_ids)}"

  tags = {
    Name        = "${var.environment}-${var.service_name}"
    Environment = "${var.environment}"
    Application = "${var.service_name}"
  }
}

resource "aws_alb_listener" "main" {
  count = "${var.enable_lb ? 1 : 0 }"

  load_balancer_arn = "${aws_alb.main[0].id}"
  port              = "${lookup(var.lb_listener, "port")}"
  protocol          = "${lookup(var.lb_listener, "protocol", "HTTP")}"
  certificate_arn   = "${lookup(var.lb_listener, "certificate_arn", "")}"
  ssl_policy        = "${lookup(var.lb_listener, "certificate_arn", "") == "" ? "" : lookup(var.lb_listener, "ssl_policy", "ELBSecurityPolicy-TLS-1-1-2017-01")}"

  default_action {
    target_group_arn = "${aws_alb_target_group.main[0].id}"
    type             = "forward"
  }
}

resource "aws_alb_target_group" "main" {
  count = "${var.enable_lb ? 1 : 0}"

  name = "${var.environment}-${var.service_name}"

  port        = "${lookup(var.lb_target_group, "host_port", 80)}"
  protocol    = "${upper(lookup(var.lb_target_group, "protocol", "HTTP"))}"
  vpc_id      = "${var.vpc_id}"
  target_type = "${lookup(var.lb_target_group, "target_type", "ip")}"

  dynamic "health_check" {
    for_each = var.lb_health_check
    content {
      enabled  = lookup(health_check.value, "enabled", null) == null ? true : health_check.value.enabled
      interval = lookup(health_check.value, "interval", null) == null ? 30 : health_check.value.interval
      path     = lookup(health_check.value, "path", null) == null ? "/" : health_check.value.path
      port     = lookup(health_check.value, "port", null) == null ? "traffic-port" : health_check.value.port
      protocol = lookup(health_check.value, "protocol", null) == null ? "HTTP" : health_check.value.protocol
      timeout  = lookup(health_check.value, "timeout", null) == null ? "5" : health_check.value.timeout
      healthy_threshold = lookup(health_check.value, "healthy_threshold", null) == null ? "3" : health_check.value.healthy_threshold
      unhealthy_threshold = lookup(health_check.value, "unhealthy_threshold", null) == null ? "3" : health_check.value.unhealthy_threshold
      matcher = lookup(health_check.value, "matcher", null) == null ? "200" : health_check.value.matcher
    }
  }

  deregistration_delay = "${lookup(var.lb_target_group, "deregistration_delay", 300)}"

  tags = {
    Name        = "${var.environment}-${var.service_name}"
    Environment = "${var.environment}"
    Application = "${var.service_name}"
  }
}

resource "aws_security_group" "alb_sg" {
  count = "${var.enable_lb ? 1 : 0}"

  name        = "${var.environment}-${var.service_name}-alb-sg"
  description = "controls access to the application LB"

  vpc_id = "${var.vpc_id}"

  ingress {
    protocol    = "tcp"
    from_port   = "${lookup(var.lb_listener, "port", 80)}"
    to_port     = "${lookup(var.lb_listener, "port", 80)}"
    cidr_blocks = "${split(",",var.lb_internal ? var.vpc_cidr : join(",",var.public_alb_whitelist))}"
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"

    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.environment}-${var.service_name}-alb-sg"
    Environment = "${var.environment}"
    Application = "${var.service_name}"
  }
}
