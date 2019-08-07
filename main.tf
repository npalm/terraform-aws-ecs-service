resource "aws_ecs_task_definition" "main" {
  family                   = "${var.environment}-${var.service_name}"
  container_definitions    = "${var.task_definition}"
  task_role_arn            = "${var.task_role_arn}"
  network_mode             = "${var.task_network_mode}"
  cpu                      = "${var.task_cpu}"
  memory                   = "${var.task_memory}"
  requires_compatibilities = ["${var.service_launch_type}"]
  execution_role_arn       = "${var.awsvpc_task_execution_role_arn}"

  dynamic "volume" {
    for_each = var.task_volumes

    content {
      name      = volume.value.name
      host_path = lookup(volume.value, "host_path", null) == null ? null : volume.value.host_path

      dynamic "docker_volume_configuration" {
        for_each = lookup(volume.value, "docker_volume_configuration", null) == null ? [] : volume.value.docker_volume_configuration

        content {
          scope         = lookup(docker_volume_configuration.value, "scope", null) == null ? null : docker_volume_configuration.value.scope
          autoprovision = lookup(docker_volume_configuration.value, "autoprovision", null) == null ? null : docker_volume_configuration.value.autoprovision
          driver        = lookup(docker_volume_configuration.value, "driver", null) == null ? null : docker_volume_configuration.value.driver
          driver_opts   = lookup(docker_volume_configuration.value, "driver_opts", null) == null ? null : docker_volume_configuration.value.driver_opts
          labels        = lookup(docker_volume_configuration.value, "labels", null) == null ? null : docker_volume_configuration.value.labels
        }
      }
    }
  }
}

# Service for awsvpc networking and ALB
resource "aws_ecs_service" "awsvpc_alb" {
  count = "${var.task_network_mode == "awsvpc" && var.enable_lb ? 1 : 0}"

  name            = "${var.service_name}"
  cluster         = "${var.ecs_cluster_id}"
  task_definition = "${aws_ecs_task_definition.main.arn}"
  desired_count   = "${var.service_desired_count}"

  load_balancer {
    target_group_arn = "${aws_alb_target_group.main[0].arn}"
    container_name   = "${lookup(var.lb_target_group, "container_name", var.service_name)}"
    container_port   = "${lookup(var.lb_target_group, "container_port", 8080)}"
  }

  launch_type = "${var.service_launch_type}"

  network_configuration {
    security_groups = ["${var.awsvpc_service_security_groups}"]
    subnets         = ["${var.awsvpc_service_subnetids}"]
  }

  depends_on = ["aws_alb_listener.main"]
}

# Service for bridge networking and ALB
resource "aws_ecs_service" "bridge_alb" {
  count      = "${var.task_network_mode == "bridge" && var.enable_lb ? 1 : 0}"
  depends_on = ["aws_alb_listener.main"]

  name            = "${var.service_name}"
  cluster         = "${var.ecs_cluster_id}"
  task_definition = "${aws_ecs_task_definition.main.arn}"
  desired_count   = "${var.service_desired_count}"

  load_balancer {
    target_group_arn = "${aws_alb_target_group.main[0].arn}"
    container_name   = "${lookup(var.lb_target_group, "container_name", var.service_name)}"
    container_port   = "${lookup(var.lb_target_group, "container_port", 8080)}"
  }

  launch_type = "${var.service_launch_type}"

  iam_role = "${var.ecs_service_role}"
}

# Service for awsvpc networking and no ALB
resource "aws_ecs_service" "awsvpc_nolb" {
  count      = "${var.task_network_mode == "awsvpc" && ! var.enable_lb ? 1 : 0}"
  depends_on = ["aws_alb_listener.main"]

  name            = "${var.service_name}"
  cluster         = "${var.ecs_cluster_id}"
  task_definition = "${aws_ecs_task_definition.main.arn}"
  desired_count   = "${var.service_desired_count}"

  network_configuration {
    security_groups = ["${var.awsvpc_service_security_groups}"]
    subnets         = ["${var.awsvpc_service_subnetids}"]
  }

  launch_type = "${var.service_launch_type}"
}

# Service for bridge networking and no ALB
resource "aws_ecs_service" "bridge_noalb" {
  count      = "${var.task_network_mode == "bridge" && ! var.enable_lb ? 1 : 0}"
  depends_on = ["aws_alb_listener.main"]

  name            = "${var.service_name}"
  cluster         = "${var.ecs_cluster_id}"
  task_definition = "${aws_ecs_task_definition.main.arn}"
  desired_count   = "${var.service_desired_count}"

  launch_type = "${var.service_launch_type}"
}
