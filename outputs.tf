output "service_url" {
  description = "Service urls."

  value = "${var.enable_lb ?
    lower(join(",", formatlist(
        "%s://%s:%s",
        aws_alb_listener.main.*.protocol,
        element(concat(aws_alb.main.*.dns_name, list("")), 0),
        aws_alb_listener.main.*.port
    ))) : ""}"
}

output "lb_dns_name" {
  description = "Loadbalancer DNS Name"

  value = "${var.enable_lb ?
    element(concat(aws_alb.main.*.dns_name, list("")), 0) : ""
  }"
}

output "lb_arn" {
  description = "Loadbalancer ARN"

  value = "${var.enable_lb ?
    element(concat(aws_alb.main.*.arn, list("")), 0) : ""
  }"
}

output "lb_zone_id" {
  description = "Loadbalancer Zone ID"

  value = "${var.enable_lb ?
    element(concat(aws_alb.main.*.zone_id, list("")), 0) : ""
  }"
}

output "task_definition_arn" {
  description = "Task definition ARN"

  value = "${aws_ecs_task_definition.main.arn}"
}

output "lb_target_group_arn" {
  description = "Loadbalancer Target Group ARN"

  value = "${var.enable_lb ?
    element(concat(aws_alb_target_group.main.*.arn, list("")), 0) : ""
  }"
}

output "lb_listener_arn" {
  description = "Loadbalancer Listener ARN"

  value = "${var.enable_lb ?
    element(concat(aws_alb_listener.main.*.arn, list("")), 0) : ""
  }"
}

output "lb_security_group_id" {
  description = "Loadbalancer Security Group id"

  value = "${var.enable_lb ?
    element(concat(aws_security_group.alb_sg.*.id, list("")), 0) : ""
  }"
}
